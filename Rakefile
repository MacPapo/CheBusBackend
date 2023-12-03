# frozen_string_literal: true

# Rakefile contains all the application-related tasks.

require_relative './system/application'
require 'gtfs'
require 'down'
require 'date'

# Enable database component.
Application.start(:database)

# Enable logger component.
Application.start(:logger)

# Add existing Logger instance to DB.loggers collection.
Application['database'].loggers << Application['logger']

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

    Rake::Task['otp:download_jar'].execute unless File.exist? 'otp.jar'
    Rake::Task['otp:download_osm'].execute unless Dir.exist? today.call.to_s

    Rake::Task['otp:update_or_replace_version'].execute

    FileUtils.cd('..')
  end

  desc 'Download otp JAR.'
  task :download_jar do
    url = 'https://repo1.maven.org/maven2/org/opentripplanner/otp/2.4.0/otp-2.4.0-shaded.jar'
    output = 'otp.jar'

    begin
      download.call(url, output)
    rescue Down::Error => e
      puts "Errore nel download del file: #{e.message}"
    end
  end

  desc 'Download OSM data.'
  task :download_osm do
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

  desc 'Structure the otp subdirectory structure.'
  task :update_or_replace_version do
    FileUtils.ln_sf(today.call.to_s, 'current')
  end
end

namespace :gtfs do
  desc 'Setup.'
  task :setup do
    # SAS
  end

  desc 'Scrap for new GTFS data and write if TRUE in DATABASE.'
  task :scrape do
    # Check for new GTFS, but
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
