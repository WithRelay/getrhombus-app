# Resque tasks
require "resque/tasks"
require 'resque/scheduler/tasks'

namespace :resque do
  task setup: :environment do
    require 'resque'

    Resque.before_fork do
      logfile = File.open(File.join(Rails.root, 'log', 'resque.log'), 'a')
      logfile.sync = true unless Rails.env.production?
      Resque.logger = MonoLogger.new(logfile)
      Resque.logger.formatter = Resque::VerboseFormatter.new
      Resque.logger.level = MonoLogger::DEBUG
      Resque.logger.info "Resque Logger Initialized!"
    end

    Resque.after_fork do
      ActiveRecord::Base.establish_connection
    end

  end

  task setup_schedule: :setup do
    require 'resque-scheduler'

    # If you want to be able to dynamically change the schedule,
    # uncomment this line.  A dynamic schedule can be updated via the
    # Resque::Scheduler.set_schedule (and remove_schedule) methods.
    # When dynamic is set to true, the scheduler process looks for
    # schedule changes and applies them on the fly.
    # Note: This feature is only available in >=2.0.0.
    # Resque::Scheduler.dynamic = true

    # The schedule doesn't need to be stored in a YAML, it just needs to
    # be a hash.  YAML is usually the easiest.
    # Resque.schedule = YAML.load(ERB.new(File.read(Rails.root.join('config', 'resque_schedule.yml'))).result)

    # If your schedule already has +queue+ set for each job, you don't
    # need to require your jobs.  This can be an advantage since it's
    # less code that resque-scheduler needs to know about. But in a small
    # project, it's usually easier to just include you job classes here.
    # So, something like this:
    # require 'jobs'
  end

  task scheduler: :setup_schedule

  # see http://stackoverflow.com/questions/5880962/how-to-destroy-jobs-enqueued-by-resque-workers - old version
  # see https://github.com/defunkt/resque/issues/49
  # see http://redis.io/commands - new commands
  desc 'Clear pending tasks'
  task clear: :environment do
    Resque.queues.each do |queue_name|
      puts "Clearing #{queue_name}..."
      Resque.remove_queue(queue_name)
    end

    # in case of scheduler - doesn't break if no scheduler module is installed
    puts "Clearing delayed..." 
    Resque.reset_delayed_queue

    puts 'Clearing stats...'
    Resque.redis.set 'stat:failed', 0
    Resque.redis.set 'stat:processed', 0

    # OR https://coderwall.com/p/ohxdmw/clearing-dead-stuck-zombie-resque-workers
    puts 'Clearing zombie workers...'
    Resque.workers.each(&:prune_dead_workers)
  end

  task clear_merchant_statuses: :environment do
    r = Redis.new
    r.keys("#{$merchant_status_redis_namespace}:*").each { |k| puts "clearing #{k}"; puts r.del(k) }
  end
end