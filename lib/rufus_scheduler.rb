# frozen_string_literal: true

# Sas
module RufusScheduler
  def self.import_stops
    puts '== IMPORT JOB STARTED =='
    Jobs::ImportActv.perform
  end

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
end
