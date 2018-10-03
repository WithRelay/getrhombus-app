# http://hone.herokuapp.com/resque/2012/08/21/resque-signals.html

fibernetics_worker: bundle exec rake resque:work QUEUE=fibernetics_event $RAILS_ENV TERM_CHILD=1 RESQUE_TERM_TIMEOUT=7
rules_worker: bundle exec rake resque:work QUEUE=rules $RAILS_ENV TERM_CHILD=1 RESQUE_TERM_TIMEOUT=7
campaign_data: bundle exec rake resque:work QUEUE=campaign_data $RAILS_ENV TERM_CHILD=1 RESQUE_TERM_TIMEOUT=7
one_time_campaigns_worker: bundle exec rake resque:work QUEUE=one_time_campaigns $RAILS_ENV TERM_CHILD=1 RESQUE_TERM_TIMEOUT=7
pending_campaigns_worker: bundle exec rake resque:work QUEUE=pending_campaigns $RAILS_ENV TERM_CHILD=1 RESQUE_TERM_TIMEOUT=7
recurring_campaigns_worker: bundle exec rake resque:work QUEUE=recurring_campaigns $RAILS_ENV TERM_CHILD=1 RESQUE_TERM_TIMEOUT=7
send_now_campaigns_worker: bundle exec rake resque:work QUEUE=send_now_campaigns $RAILS_ENV TERM_CHILD=1 RESQUE_TERM_TIMEOUT=7
welcome_email_and_incomplete_signup_worker: bundle exec rake resque:work QUEUE=welcome_email,incomplete_signup $RAILS_ENV TERM_CHILD=1 RESQUE_TERM_TIMEOUT=7
csv_contact_and_customer_import_worker: bundle exec rake resque:work QUEUE=csv_contact_import,csv_customer_import $RAILS_ENV TERM_CHILD=1 RESQUE_TERM_TIMEOUT=7
worker: bundle exec rake resque:work QUEUE=* $RAILS_ENV TERM_CHILD=1 RESQUE_TERM_TIMEOUT=7
scheduler: bundle exec rake resque:scheduler $RAILS_ENV LOGFILE=./log/resque_scheduler.log