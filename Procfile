# http://hone.herokuapp.com/resque/2012/08/21/resque-signals.html

fibernetics_worker: bundle exec rake resque:work QUEUE=fibernetics_event $RAILS_ENV TERM_CHILD=1 RESQUE_TERM_TIMEOUT=7
worker: bundle exec rake resque:work QUEUE=* $RAILS_ENV TERM_CHILD=1 RESQUE_TERM_TIMEOUT=7
scheduler: bundle exec rake resque:scheduler $RAILS_ENV LOGFILE=./log/resque_scheduler.log