class Api::V1::RemindersController < API::V1::BaseController
  respond_to :html, :json

  def create
    @reminder = current_user.reminders.build(reminder_params)
    saved_reminder = @reminder.save
    @reminder.enqueue_notification_jobs if saved_reminder
    render json: json_message(saved_reminder).merge({ notice: 'Reminder successfully Created' })
  end

  private

  def json_message(saved_reminder)
    message = saved_reminder ? { status: 200 } : { error: @reminder.errors.full_messages, status: 400 }
    return message
  end

  def reminder_params
    # enums are define as integer but params are in string and rails is not converting string to integer
    params.require(:reminder).permit(:channel, :repeat_days, :date_time, :frequency_type, :text).tap do |c|
                                    c[:channel] = c[:channel].to_i; c[:frequency_type] = c[:frequency_type].to_i
                                    c[:date_time] = c[:date_time].present? ? c[:date_time].in_time_zone(current_user.time_zone) : nil
                                  end
  end
end
