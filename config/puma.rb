workers ENV.fetch("WEB_CONCURRENCY") { 4 }

threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
threads threads_count, threads_count

preload_app!

port        ENV.fetch("PORT") { 9292 }
environment ENV.fetch("RACK_ENV") { "development" }

plugin :tmp_restart
