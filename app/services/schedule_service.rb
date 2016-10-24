# service that schedule everthings
class ScheduleService

  def initialize(object)
    @object = object
    @service_class = "#{object.class}Service".constantize
    @job = "#{object.class}Job".constantize
  end

  def schedule_now
    @job.perform_now(@object.id)
  end
end
