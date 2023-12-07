# frozen_string_literal: true

# Job
module Jobs
  include Models

  # Scrape
  class ScrapeGtfs
    FILE_NAME = 'gtfs_urls.csv'
    STATUS = { uptodate: 0, outdated: 1 }.freeze

    def self.perform
      puts bootstrap ? 'DONE' : "FAIL: File #{FILE_NAME} not found or Empty."
    end

    def self.bootstrap
      return false unless File.exist?(FILE_NAME)

      url_data = CSV.read(FILE_NAME)
      return false if url_data.empty?

      url_data.each do |row|
        category, url = row # row[0] -> CATEGORY, row[1] -> URL
        next unless valid_url?(url)

        gtfs_status = find_or_initialize_gtfs_status(url, category)
        next if up_to_date?(gtfs_status)

        process_url(url, category, gtfs_status)
      end
    end

    def self.valid_url?(url)
      uri = URI.parse(url)
      uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
    rescue URI::InvalidURIError
      false
    end

    def self.find_or_initialize_gtfs_status(url, category)
      Models::GtfsStatus.where(url:, category:).first || { url:, category:, updated_at: nil }
    end

    def self.up_to_date?(gtfs_status)
      return false unless gtfs_status && !gtfs_status.is_a?(Hash)

      latest_update = fetch_latest_update(URI.parse(gtfs_status.url))
      gtfs_status.updated_at >= latest_update
    end

    def self.process_url(url, category, gtfs_status)
      uri = URI.parse(url)
      latest_update = fetch_latest_update(uri)
      return if latest_update.nil? || latest_update == gtfs_status[:updated_at]

      out_file_name = download_and_process(uri, category)
      update_database(uri, category, latest_update, out_file_name)
    end

    def self.fetch_latest_update(uri)
      parse_date = ->(date) { DateTime.parse(date).strftime('%F') }
      request = Net::HTTP.new(uri.host, uri.port)
      request.use_ssl = uri.scheme == 'https'
      response = request.head(uri.request_uri)

      response.code == '200' ? parse_date.call(response['Last-Modified']) : nil
    rescue StandardError
      nil
    end

    def self.download_and_process(uri, category)
      file_name = generate_filename(category, uri)
      delete_old_file(file_name)
      download(uri, file_name)
      file_name
    end

    def self.generate_filename(category, uri)
      base_name = File.basename(uri.to_s, '.zip')
      "otp/current/#{category}_#{base_name}.gtfs.zip"
    end

    def self.delete_old_file(filename)
      FileUtils.rm(filename) if File.exist?(filename)
    end

    def self.download(uri, filename)
      temp_file = Down.download(uri)
      FileUtils.mv(temp_file.path, filename)
      puts "File downloaded as #{filename}"
    end

    def self.update_database(uri, category, latest_update, filename)
      gtfs = extract_gtfs(filename)
      agency = extract_agencies(gtfs.agencies)[0]
      agency_id = add_or_find_agency(agency)

      add_or_update_gtfs_status(agency_id, uri.to_s, category, latest_update)
    end

    def self.extract_gtfs(filename)
      GTFS::Source.build(filename)
    end

    def self.extract_agencies(agencies)
      agencies.map do |x|
        { agency_id: x.id, agency_name: x.name }
      end
    end

    def self.add_or_find_agency(agency)
      res = Models::Agency.find_or_create(agency_id: agency[:agency_id]) { |a| a.agency_name = agency[:agency_name] }
      res.id
    end

    def self.add_or_update_gtfs_status(agency_id, url, category, latest_update)
      Models::GtfsStatus.find_or_create(url:, category:) do |g|
        g.agency_id = agency_id
        g.updated_at = latest_update
      end
    end
  end
end
