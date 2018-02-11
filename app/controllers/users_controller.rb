class UsersController < ApplicationController

  before_action :set_user
  load_and_authorize_resource
  
  include DashboardNotification
  include AdditionalUserActions
  include ManagedAccountActions
  include DashboardData

  before_action :set_notifications, except: [:show, :customer_csv_template, :contact_csv_template, :add_card_info, :add_subscription, :add_rhombus_number,
                                             :add_profile_info, :remove_twitter_integration, :remove_stripe_integration, :verify_hosted_sms_order]

  def show
    if current_user.is_merchant?
      set_notifications
      # all the methods are in concerns/dashboard_data
      @dashboard_overall_section = dashboard_customers_and_transactions
      @dashboard_msg_perform = dashboard_analytics_section
      @dashboard_transactions = dashboard_transactions
      @dashboard_messages_data = dashboard_messages_data
    else 
      redirect_to user_transactions_path
    end
  end

  # DELETE /users/1
  def destroy
    @user.destroy
    respond_to do |format|
      format.html { redirect_to users_url, notice: 'Account deleted' }
      format.json { head :no_content }
    end
  end

private
  # Use callbacks to share common setup or constraints between actions.
  def set_user
    @user = current_user
  end

  def full_user_params
    nested_user_params = user_params
    tos_params = { ip: request.remote_ip, user_agent: request.user_agent, tos_date: Time.current }
    nested_user_params[:stripe_creds_attributes]["0"].merge!(tos_params)
    nested_user_params
  end

  def user_params
    params.require(:user).permit(:id, :org_type, :org_name, :url, :org_tax_id, :description, :tos_acceptance,
      bank_accounts_attributes: [:id, :routing_number, :country, :currency, :account_number, :institution_number],
      people_attributes: [:id, :gender, :business_name, :full_name, :dob, :last4, :role, :_destroy, 
        #address_attributes: [:street_address, :suite, :id, :city, :state_province, :postal_code, :country]
      ],
      address_attributes: [:street_address, :suite, :id, :city, :state_province, :postal_code, :country],
      stripe_creds_attributes: [:id, :charges_enabled, :payouts_enabled])
  end

end
