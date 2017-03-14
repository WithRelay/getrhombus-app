class UsersController < ApplicationController

  include DashboardNotification
  include AdditionalUserActions

  before_action :set_user
  before_action :set_notifications

  # do i need this?
  load_and_authorize_resource except: [:customer_csv_template]


  def show

    # handle_referrer_and_welcome_email
    # delete_captured_payment_session
    # Transaction.process_captured_payment(@user, params) if current_user.user_level == 0 && params[:captured_amt].present?
    @last6_transactions = Transaction.includes(:user).where(team_id: current_user.id).order(created_at: :desc).last(6)
    # @token = TextingService.get_twilio_capibility_token if current_user.user_level == 1
    
    customers = current_user.merchant_customers
    new_customers = customers.select{ |c| c.created_at >= 1.week.ago.utc }
    transactions = Transaction.where( team_id: current_user.id)
    transactions_today = transactions.select{|t| t.created_at >= Time.current.beginning_of_day}
    
    @conversations_per_hour = Conversation.conversation_per_hour(current_user)

    #data for chart, includes both fb_msg and sms 
    @msg_data_for_chart = all_messages_count_in_30_days
    
    #message_count method returns hash of message_per_day , fb_percent and sms_percent  
    @message_counts = message_count

    @avg_handle_time = avg_handle_time.round(2)

    @total_transactions = transactions.sum(:amount)
    @transactions_today = transactions_today.present? ? transactions_today.sum(:amount) : 0  
    @transactions_today_count = transactions_today.count

    @unread_message_count = Conversation.get_merchant_total_unread_msgs_count(current_user)
    @unread_messages_last_5 = ConversationRef.get_last_msgs_from_all_merchant_convs(current_user).last(5)
    # binding.process_captured_payment

    @all_customers_count = customers.count
    @new_customers_count = new_customers.count

  end

  # DELETE /users/1
  def destroy
    @user.destroy
    respond_to do |format|
      format.html { redirect_to users_url, notice: 'Account deleted' }
      format.json { head :no_content }
    end
  end

  def sms_usage
  end

  def leads_contacts
    uid_type = params[:uid_type] || 'phone_number'
    @leads_contacts = current_user.merchant_contacts.where(uid_type: uid_type).includes(:contacts)
  end

private
  # Use callbacks to share common setup or constraints between actions.
  def set_user
    @user = current_user
  end

  def full_user_params
    nested_user_params = user_params
    tos_params = { ip: request.remote_ip, user_agent: request.user_agent, uid_type: 0, tos_date: Time.current }
    nested_user_params[:stripe_creds_attributes]["0"].merge!(tos_params)
    nested_user_params
  end

  def user_params
    params.require(:user).permit(:id, :org_type, :org_name, :url, :org_tax_id, :description, :tos_acceptance,
      bank_accounts_attributes: [:id, :routing_number, :country, :currency, :account_number,
                                 :institution_number],
      people_attributes: [:id, :gender, :business_name, :full_name, :dob, :last4, :role, :_destroy,
      address_attributes: [:street_address, :suite, :state_province, :id, :country, :postal_code, :state_province,
                           :city]],
      stripe_creds_attributes: [:id, :charges_enabled, :transfers_enabled])
  end

  def handle_referrer_and_welcome_email
    Referrer.save_referrer_with_id(session[:referrer_id], current_user.id) if session[:referrer_id].present?
    Referrer.save_referrer_with_uid(session[:referrer_uid], current_user.id) if session[:referrer_uid].present?
    # Change this logic at some point
    # current_user.send_welcome_email if current_user.sign_in_count == 1
  end

#These methods below are used to collect data for merchant dashboard
  def all_messages_count_in_30_days
    txt_messages = sent_and_received_messages('Message')
                    .where("created_at >=?", 30.days.ago.utc)
                    .group("DAY(created_at)").count

    fb_messages = sent_and_received_messages('FbMessage')
                    .where("created_at >=?", 30.days.ago.utc)
                    .group("DAY(created_at)").count

    #prepare data for chart 
    #this will merge count of sms and fb_msg and add the coutes on the same day              
    txt_messages.merge(fb_messages){|k, mv, fv| mv + fv}
  end

  def message_count
    txt_msg, fb_msg = sent_and_received_messages('Message'), 
                      sent_and_received_messages('FbMessage')

    txt_msg_today = txt_msg.select {|t| t.created_at >= Time.current.beginning_of_day}
    fb_msg_today   = fb_msg.select  {|t| t.created_at >= Time.current.beginning_of_day}
    today_msgs_count = txt_msg_today.count + fb_msg_today.count

    # first_msg_date = Time.current - 2.days #txt_msg.first.created_at < fb_msg.first.created_at ? txt_msg.first.created_at : fb_msg.first.created_at 
    # last_msg_date = Time.current#txt_msg.last.created_at > fb_msg.last.created_at ? txt_msg.last.created_at : fb_msg.last.created_at
    
    # msg_time_interval = (last_msg_date - first_msg_date)/1.days
    
    # msg_per_day = total_msgs_count/msg_time_interval

    fb_msg_percent = fb_msg_today.present? ? 100 * fb_msg_today.count/today_msgs_count : 0
    txt_msg_percent = txt_msg_today.present? ? 100 * txt_msg_today.count/today_msgs_count : 0

    {msg_today: today_msgs_count, fb_msg_percent: fb_msg_percent.round(2), txt_msg_percent: txt_msg_percent.round(2)} 
  end

  def sent_and_received_messages(class_name)
    class_name.constantize.where("user_id= ? OR user_id_to= ?", current_user.id, current_user.id)
  end

  def avg_handle_time
    avg = Conversation.where(merchant_id: current_user.id).where.not(resolution: nil)
                      .average("DATEDIFF(updated_at,created_at)")            

    avg.present? ? avg/1.minutes : avg
  end

end
