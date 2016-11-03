worker: TERM_CHILD=1 RESQUE_TERM_TIMEOUT=7 $RAILS_ENV bundle exec rake resque:work QUEUE=*
scheduler: $RAILS_ENV bundle exec rake resque:scheduler LOGFILE=./log/resque_scheduler.log
