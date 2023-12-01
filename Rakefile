# frozen_string_literal: true

# Rakefile contains all the application-related tasks.

require_relative './system/application'
require 'gtfs'

# Enable database component.
Application.start(:database)

# Enable logger component.
Application.start(:logger)

# Add existing Logger instance to DB.loggers collection.
Application['database'].loggers << Application['logger']

namespace :db do
  desc 'Insert data in the database.'
  task :import do
    RufusScheduler.import_stops
  end
end

# Shell

irb = proc do |env|
  ENV['RACK_ENV'] = env
  trap('INT', 'IGNORE')
  dir, base = File.split(FileUtils::RUBY)
  cmd = if base.sub!(/\Aruby/, 'irb')
          File.join(dir, base)
        else
          "#{FileUtils::RUBY} -S irb"
        end
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

desc 'Generate project documentation using yard.'
task :docs do
  sh %(yard doc *.rb app/ lib/)
end
