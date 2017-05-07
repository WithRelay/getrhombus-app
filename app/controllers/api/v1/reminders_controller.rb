class Api::V1::RemindersController < API::V1::BaseController


  def create
    reminder = current_user.reminders.build(reminder_params)
    customer_contact = params[:reminder][:customer_id].split(',')
    reminder_campaign = if customer_contact[1] == 'user'
                          reminder.campaign_lists.build(merchant_customer_id: customer_contact[0])
                        else
                          reminder.campaign_lists.build(merchant_contact_id: customer_contact[0])
                        end
    saved_reminder = reminder.save
    reminder.enqueue_jobs if saved_reminder
    status = saved_reminder ? { status: 200 } : { status: 400 }
    message = saved_reminder ? { notice: 'Reminder successfully Created' } : { error: reminder.errors.full_messages }
    render json: status.merge(message)
  end

  def edit
    reminder = current_user.reminders.find_by_id(params[:id])
    customer_id = reminder.campaign_lists[0].merchant_customer_id
    contact_customer = customer_id.present? ? customer_id : reminder.campaign_lists[0].merchant_contact_id
    user = User.where(id: contact_customer).select('id, phone_number')
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
