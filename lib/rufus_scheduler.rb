# frozen_string_literal: true

# require 'rufus-scheduler'
# scheduler = Rufus::Scheduler.new

# scheduler.every '24h' do
#   UpdateDatabaseJob.perform
# end

# scheduler.every '20s' do
#   puts "== IMPORT JOB STARTED =="
#   ImportActvJob.perform
# end

# scheduler.join # Questo tiene in esecuzione lo scheduler

puts "== IMPORT JOB STARTED =="
Jobs::ImportActvJob.perform
