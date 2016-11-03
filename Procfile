worker: RAILS_ENV=development TERM_CHILD=1 RESQUE_TERM_TIMEOUT=7 bundle exec rake resque:work QUEUE=*
scheduler: RAILS_ENV=development bundle exec rake resque:scheduler LOGFILE=./log/resque_scheduler.log
