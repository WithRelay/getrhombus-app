require 'ar_after_transaction'
require 'resque/failure/multiple'
require 'resque/failure/redis'

config = YAML.load_file(Rails.root.join('config', 'resque.yml'))

# configure redis connection
Resque.redis = config[Rails.env]

# set a custom namespace for redis (optional)
Resque.redis.namespace = "resque:relay"

Resque.schedule = YAML.load(ERB.new(File.read(Rails.root.join('config', 'resque_schedule.yml'))).result)

Resque::Failure::Multiple.classes = [Resque::Failure::Redis]
Resque::Failure.backend = Resque::Failure::Multiple

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