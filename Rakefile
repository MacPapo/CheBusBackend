# frozen_string_literal: true

# Rakefile contains all the application-related tasks.

require_relative './system/application'
require 'gtfs'
require 'down'
require 'date'
require 'uri'
require 'set'

GTFS_URL = 'gtfs_urls.csv'

BUILD_CONFIG =
  {
    osmWayPropertySet: 'it'
  }.freeze

OTP_CONFIG =
  {
    otpFeatures: {
      ParallelRouting: true,
      FloatingBike: false
    }
  }.freeze

ROUTER_CONFIG =
  {
    timeouts: [5, 4, 3, 1],
    routingDefaults: { driveOnRight: true }
  }.freeze

OTP_MEMORY = 6
BUILD_GRAPH_COMMAND =
  ->(jar, dir) { "java -Xmx#{OTP_MEMORY}G -jar #{jar} --build --save #{dir}" }

CURRENT_JAR   = 'otp/otp.jar'
CURRENT_GRAPH = 'otp/current'

URL_JAR = 'https://repo1.maven.org/maven2/org/opentripplanner/otp/2.4.0/otp-2.4.0-shaded.jar'
URL_OSM = 'http://download.geofabrik.de/europe/italy/nord-est-latest.osm.pbf'

migrate =
  lambda do |version|
    # Enable Sequel migration extension.
    Sequel.extension(:migration)

    # Perform migrations based on migration files in a specified directory.
    Sequel::Migrator.apply(Application['database'], 'db/migrate', version)
  end

today = -> { Date.today.strftime('%Y-%m-%d') }

download =
  lambda do |url, output|
    temp_file = Down.download(url)
    FileUtils.mv(temp_file.path, output)
    puts "DONE: File downloaded as #{output}"
  end

add_json_config =
  lambda do |filename, data|
    File.write(filename, data)
  end

fprint = ->(str) { printf('%-40s', str) }

namespace :argo do
  desc 'Setup Argo.'
  task :setup do
    puts 'Starting setup proces...'
    Rake::Task['db:migrate'].execute
    Rake::Task['otp:setup'].execute
    Rake::Task['gtfs:setup'].execute
    Rake::Task['otp:build_graph'].execute
    puts 'Setup done!'
  end
end

namespace :db do
  desc 'Migrate the database.'
  task :migrate do
    migrate.call(nil)
  end

  desc 'Rolling back latest migration.'
  task :rollback do |_, _args|
    current_version = Application['database'].fetch('SELECT * FROM schema_info').first[:version]

    migrate.call(current_version - 1)
  end
end

namespace :otp do
  desc 'Setup.'
  task :setup do
    Dir.mkdir('otp') unless Dir.exist? 'otp'
    FileUtils.cd('otp')
    Rake::Task['downloader:all'].execute
    Rake::Task['otp:link_new_version'].execute
    FileUtils.cd(today.call.to_s)
    Rake::Task['otp:add_config'].execute
    FileUtils.cd('../../')
  end

  desc 'Update or replace current link.'
  task :link_new_version do
    FileUtils.rm_f('current') if File.symlink?('current')
    FileUtils.ln_s(today.call.to_s, 'current')
  end

  desc 'Add Config.'
  task :add_config do
    add_json_config.call('build-config.json',  Oj.dump(BUILD_CONFIG))
    add_json_config.call('router-config.json', Oj.dump(ROUTER_CONFIG))
    add_json_config.call('otp-config.json', Oj.dump(OTP_CONFIG))
  end

  desc 'Build or Rebuild graph.'
  task :build_graph do
    # Esegui il comando BUILD_GRAPH
    system(BUILD_GRAPH_COMMAND.call(CURRENT_JAR, CURRENT_GRAPH))
  end
end

namespace :downloader do
  error_download = ->(e) { puts "FAIL: Error downloading file: #{e.message}" }

  desc 'Download all.'
  task :all do
    Rake::Task['downloader:otp_jar'].execute unless File.exist? 'otp.jar'
    Rake::Task['downloader:osm'].execute unless Dir.exist? today.call.to_s
  end

  desc 'Download otp JAR.'
  task :otp_jar do
    fprint.call('Downloading OTP')
    download.call(URL_JAR, 'otp.jar')
  rescue Down::Error => e
    error_download.call(e)
  end

  desc 'Download OSM data.'
  task :osm do
    fprint.call('Downloading OSM')
    output_dir = today.call.to_s
    file = 'nord-est.osm.pbf'
    begin
      FileUtils.mkdir_p output_dir unless Dir.exist? output_dir
      download.call(URL_OSM, "#{output_dir}/#{file}")
    rescue Down::Error => e
      error_download.call(e)
    end
  end
end

namespace :gtfs do
  desc 'Setup all GTFS tasks.'
  task :setup do
    Rake::Task['gtfs:import_categories'].execute
    Rake::Task['gtfs:scrape'].execute
    Rake::Task['gtfs:create_clusters'].execute
  end

  desc 'Import all Categories of Transports'
  task :import_categories do
    categories = Set.new
    CSV.foreach(GTFS_URL) do |row|
      next unless row.size == 2

      categories.add? row[0]&.upcase
    end

    unless categories.empty?
      Application['database'].transaction do
        new_categories = categories.reject do |name|
          Models::Category.where(name:).first
        end

        multi_category = new_categories.map do |name|
          Models::Category.new(name:)
        end
        
        Models::Category.multi_insert(multi_category) unless multi_category.empty?
      end
    end
  end

  desc 'Scrap for new GTFS data and write if TRUE in DATABASE.'
  task :scrape do
    fprint.call('Importing GTFS data')
    Jobs::ScrapeGtfs.perform
  end

  desc 'Import GTFS stop clusters.'
  task :create_clusters do
    fprint.call('Importing Clusters data')
    Jobs::ImportStopClusters.perform
  end
end

# Shell

irb = proc do |env|
  ENV['RACK_ENV'] = env
  trap('INT', 'IGNORE')
  dir, base = File.split(FileUtils::RUBY)
  cmd = base.sub!(/\Aruby/, 'irb') ? File.join(dir, base) : "#{FileUtils::RUBY} -S irb"
  sh "#{cmd} -r ./system/boot"
end

desc 'Open irb shell in test mode'
task :test_irb do
  irb.call('test')
end

desc 'Open irb shell in development mode'
task :dev_irb do
  irb.call('development')
end

desc 'Open irb shell in production mode'
task :prod_irb do
  irb.call('production')
end

# DOCUMENTATION

desc 'Generate project documentation using yard.'
task :docs do
  sh %(yard doc *.rb app/ lib/)
end
