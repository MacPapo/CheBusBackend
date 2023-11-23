# frozen_string_literal: true

module RufusScheduler

  def self.first_import
    puts "== IMPORT JOB STARTED =="
    Jobs::ImportActvGeo.perform
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
