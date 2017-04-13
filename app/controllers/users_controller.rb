class UsersController < ApplicationController

  include DashboardNotification
  include AdditionalUserActions
  include DashboardData

  before_action :set_user
  before_action :set_notifications, except: [:customer_csv_template]

  # do i need this?
  # load_and_authorize_resource except: [:customer_csv_template]

  def show
    #all the methods are in concerns/databoard_data
    @overall_section = customers_and_transactions
    @msg_perform = analytics_section
    @transactions = transactions
    @messages_data = messages_datas
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
    @amount_balance = current_user.account_balance
    @last4 = current_user.last4
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

end
