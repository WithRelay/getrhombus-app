require 'ar_after_transaction'
require 'resque'
require 'resque-scheduler'

config = YAML.load_file(Rails.root.join('config', 'resque.yml'))
schedule = YAML.load_file(Rails.root.join('config', 'resque_schedule.yml'))

# configure redis connection
Resque.redis = config[Rails.env]
#Resque.logger = MonoLogger.new(File.open("#{Rails.root}/log/resque.log", "w+"))
Resque.logger.formatter = Resque::VerboseFormatter.new

# configure the schedule
Resque.schedule = schedule

# set a custom namespace for redis (optional)
Resque.redis.namespace = "resque:getrhombus"

# Only enqueue after transactions are done
Resque.class_eval do
  class << self
    alias_method :enqueue_without_transaction, :enqueue
    def enqueue(*args)
      ActiveRecord::Base.after_transaction do
        enqueue_without_transaction(*args)
      end
    end
  end
end