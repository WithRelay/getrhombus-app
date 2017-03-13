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

    @messages = current_user.messages.where("created_at: >=",  30.days.ago.utc).group("DAY(created_at)")
    @total_transactions = transactions.sum(:amount)
    @transactions_today = transactions_today.present? ? transactions_today.sum(:amount) : 0  
    @transactions_today_count = transactions_today.count

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
end
