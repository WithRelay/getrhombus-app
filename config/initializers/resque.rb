require 'resque'
require 'resque-scheduler'

config = YAML.load_file(Rails.root.join('config', 'resque.yml'))
#schedule = YAML.load_file(Rails.root.join('config', 'schedule.yml'))

# configure redis connection
Resque.redis = config[Rails.env]

# configure the schedule
#Resque.schedule = schedule

# set a custom namespace for redis (optional)
Resque.redis.namespace = "resque:getrhombus"