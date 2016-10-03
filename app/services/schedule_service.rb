# service that schedule everthings
class ScheduleService

  def initialize(object)
    @object = object
    @service_class = "#{object.class}Service".constantize
    @job = "#{object.class}EmailJob".constantize
  end

  def schedule_with_date_time(date_time)
    @job.set(wait: date_time).perform_later(@object) if date_time.present?
  end

  def scheduled_date_time
    @object.date_time if @object.class.column_names.include? 'date_time'
  end
end
