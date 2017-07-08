class Api::V1::RemindersController < API::V1::BaseController
  before_action :set_reminder, only: [:update]

  def create
    @reminder = nil
    ActiveRecord::Base.transaction do
      @mc_ary = params[:reminder][:mc_id].split('-')
      raise ActiveRecord::RecordNotFound unless @mc_ary.second.constantize.exists? @mc_ary.first
      @reminder_params = reminder_params    
      
      @reminder = current_user.reminders.create!(@reminder_params)
      @list = current_user.lists.create!(list_params)
      @list.campaign_lists.create!(campaign_id: @reminder.id)
      @list.user_lists.create!(customer_contact_id: @mc_ary.first, customer_contact_type: @mc_ary.second)
      @reminder.enqueue_jobs
      render json: { notice: 'Reminder successfully created' }
    end
  rescue Exception => e
    render json: { error: e.message }, status: 500
  end

  # only some attributes can be updated
  def update
    unless @reminder.inactive?
      if @reminder.update(reminder_params)
        @reminder.change_campaign_job
        render json: { notice: 'Reminder updated', id: @reminder.id, text: @reminder.text, frequency_text: @reminder.one_time? ? 'Once' : 'Repeat', 
                       time: @reminder.date_time.strftime("%-I:%M %p"), date_time: @reminder.date_time.strftime("%Y-%m-%d %l:%M %p"), 
                       frequency: Reminder.frequency_types[@reminder.frequency_type], repeat_days: @reminder.repeat_days }
      else
        render json: { error: @reminder.errors.full_messages }, status: 500
      end
    else
      render json: { error: "You need to activate an inactive reminder before updating it." }, status: 500
    end
  end

  private

  def set_reminder
    @reminder = current_user.reminders.find(params[:id])
  end

  def reminder_params
    # enums are define as integer but params are in string and rails is not converting string to integer
    params.require(:reminder).permit(:channel, :repeat_days, :date_time, :frequency_type, :text).tap do |c|
                                    c[:channel] = c[:channel].to_i
                                    c[:frequency_type] = c[:frequency_type].to_i
                                    c[:repeat_days] = nil if c[:frequency_type] == 0
                                    c[:date_time] = c[:date_time].present? ? c[:date_time].in_time_zone(current_user.time_zone) : nil
                                  end
  end

  def list_params
    { 
      origin: List.origins[:merchant], list_type: @mc_ary.second == 'MerchantCustomer' ? :customer : :contact, 
      channel: @reminder_params[:channel] == 0 ? :sms : :messenger, campaign_type: List.campaign_types[:reminder]
    }
  end
end
