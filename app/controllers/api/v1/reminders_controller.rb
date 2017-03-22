class Api::V1::RemindersController < API::V1::BaseController


  def create
    reminder = current_user.reminders.build(reminder_params)
    reminder_campaign = reminder.campaign_lists.build(user_id: params[:reminder][:customer_id])
    saved_reminder = reminder.save
    reminder.enqueue_jobs if saved_reminder
    status = saved_reminder ? { status: 200 } : { status: 400 }
    message = saved_reminder ? { notice: 'Reminder successfully Created' } : { error: reminder.errors.full_messages }
    render json: status.merge(message)
  end

  def edit
    reminder = Reminder.find_by_id(params[:id])
    user = User.where(id: reminder.campaign_lists[0].list_id).select('id, phone_number')
    render json: { reminder: reminder, reminder_lists: user }
  end

  private

  def reminder_params
    # enums are define as integer but params are in string and rails is not converting string to integer
    params.require(:reminder).permit(:channel, :repeat_days, :date_time, :frequency_type, :text).tap do |c|
                                    c[:channel] = c[:channel].to_i; c[:frequency_type] = c[:frequency_type].to_i
                                    c[:date_time] = c[:date_time].present? ? c[:date_time].in_time_zone(current_user.time_zone) : nil
                                  end
  end
end
