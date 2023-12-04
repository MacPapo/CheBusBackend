# frozen_string_literal: true

# Rakefile contains all the application-related tasks.

require_relative './system/application'
require 'gtfs'
require 'down'
require 'date'
require 'uri'

# Enable database component.
Application.start(:database)

# Enable logger component.
Application.start(:logger)

# Add existing Logger instance to DB.loggers collection.
Application['database'].loggers << Application['logger']

BUILD_CONFIG =
  { osmWayPropertySet: 'it' }.freeze

ROUTER_CONFIG =
  {
    timeouts: [5, 4, 3, 1],
    routingDefaults: { driveOnRight: true }
  }.freeze

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
    puts "File scaricato e salvato come #{output}"
  end

add_json_config =
  lambda do |filename, data|
    File.write(filename, data)
  end

namespace :db do
  desc 'Insert data in the database.'
  task :import do
    RufusScheduler.import_stops
  end

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

    Rake::Task['downloader:otp_jar'].execute unless File.exist? 'otp.jar'
    Rake::Task['downloader:osm'].execute unless Dir.exist? today.call.to_s

    Rake::Task['otp:update_version'].execute

    FileUtils.cd(today.call.to_s)
    Rake::Task['otp:add_config'].execute

    FileUtils.cd('../../')
  end

  desc 'Update or replace current link.'
  task :update_version do
    FileUtils.rm_f('current') if File.symlink?('current')
    FileUtils.ln_s(today.call.to_s, 'current')
  end

  desc 'Add Config.'
  task :add_config do
    add_json_config.call('build-config.json',  Oj.dump(BUILD_CONFIG))
    add_json_config.call('router-config.json', Oj.dump(ROUTER_CONFIG))
  end
end

namespace :downloader do
  desc 'Download otp JAR.'
  task :otp_jar do
    url = 'https://repo1.maven.org/maven2/org/opentripplanner/otp/2.4.0/otp-2.4.0-shaded.jar'
    output = 'otp.jar'

    begin
      download.call(url, output)
    rescue Down::Error => e
      puts "Errore nel download del file: #{e.message}"
    end
  end

  desc 'Download OSM data.'
  task :osm do
    url = 'http://download.geofabrik.de/europe/italy/nord-est-latest.osm.pbf'
    output_dir = today.call.to_s
    file = 'nord-est.osm.pbf'

    begin
      FileUtils.mkdir_p output_dir unless Dir.exist? output_dir
      download.call(url, "#{output_dir}/#{file}")
    rescue Down::Error => e
      puts "Errore nel download del file: #{e.message}"
    end
  end
end

namespace :gtfs do
  desc 'Setup.'
  task :setup do
    # SAS
  end

  desc 'Scrap for new GTFS data and write if TRUE in DATABASE.'
  task :scrape do
    Jobs::ScrapeGtfs.perform
  end

  desc 'Download the GTFS data if new versione is available.'
  task :download do
    # Check the DB and download only the new version of GTFS
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
