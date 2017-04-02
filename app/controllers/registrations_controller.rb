class RegistrationsController < Devise::RegistrationsController

  include AdditionalUserActions
  include DashboardNotification
  include CheckUserProfile

  before_action :set_notifications, only: [:billing_information, :account_settings, :business_settings]

  def update
    self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)
    #prev_unconfirmed_email = resource.unconfirmed_email if resource.respond_to?(:unconfirmed_email)

    message = check_params_with_update
    url = request.referrer if setting_pages_present?
    yield resource if block_given?
    if message.blank? && update_resource(resource, account_update_params)
      set_flash_message = set_update_flash_messages(message)
      update_stripe_email if set_flash_message[:account_settings].present?
      # flash_key = update_needs_confirmation?(resource, prev_unconfirmed_email) ? :update_needs_confirmation : :updated
      # set_flash_message :notice, flash_key
      flash[:notice] = set_flash_message[:success] if is_flashing_format?
      bypass_sign_in resource, scope: resource_name
      redirect_to url || after_update_path_for(resource)
    else
      set_flash_message = set_update_flash_messages(message)
      flash[:error] = message.is_a?(Stripe::InvalidRequestError) ? set_flash_message[:error].message : set_flash_message[:error]
      clean_up_passwords resource
      set_minimum_password_length
      redirect_to previous_url
    end
  end

  def create
    set_captured_payment_session
    build_resource(sign_up_params)
    save_resource
    yield resource if block_given?
    if resource.persisted?
      sign_up(resource_name, resource)
      respond_with resource, location: after_sign_up_path_for(resource)
    else
      flash[:error] = resource.errors.full_messages
      clean_up_passwords resource
      set_minimum_password_length
      render :new
    end
  end

  def add_profile_info
    @user = current_user
    @user.people = [@user.people.first || Person.new]
  end

  def update_stripe_email
    StripeManagedAccountService.new(current_user).update_account_email if resource.bank_accounts.present?
  end

  def billing_information; end

  def account_settings
    if current_user.is_merchant?
      @user = current_user
      @user.people = [@user.people.first || Person.new]
    end
  end

  def check_params_with_update
    msg = nil
    if set_update_flash_messages[:subscription].present? && current_user.is_merchant?
      #subscription = create_saas_subscription
      msg = ''# (subscription.third ? subscription.third : "We are unable to start a subscription for you") unless subscription.first
    elsif set_update_flash_messages[:rhombus_number].present? && current_user.is_merchant?
      unless current_user.buy_number(params['user'])
       msg = 'Something went wrong. We were unable to provision a number for you. A member of our support team will contact you shortly.'
      end
    elsif set_update_flash_messages[:card_info].present? || set_update_flash_messages[:billing_info].present?
      set_captured_payment_session if current_user.is_customer? && set_update_flash_messages[:card_info].present?
      add_token = current_user.add_token_for_user(params[:user][:card_token])
      msg = (add_token.third ? add_token.third : "We are unable to add your card to your profile.") unless add_token.first
    end
    msg
  end

  def business_settings; end

  def add_rhombus_number; end

  def add_subscription; end

  def add_card_info; end

  def auto_recharge
    if params['user']['auto_reload'] == '1'
      auto_reload_amt = params['user']['auto_reload_amt']
      current_user.update(auto_reload_amt: auto_reload_amt, auto_reload: true)
      flash[:notice] = "Auto recharge with #{auto_reload_amt}"
    else
      current_user.update(auto_reload: false)
      flash[:notice] = "Auto recharge disabled"
    end
    redirect_to sms_usage_user_path
  end

  def add_funds
    current_user.account_balance += params['user']['account_balance'].to_i
    current_user.save
    flash[:notice] = "Account balanced updated, Now your total balance is: #{current_user.account_balance}"
    redirect_to sms_usage_user_path
  end

  protected

  def create_saas_subscription
    begin
      # or you can check if the selected plan is the free plan
      token_res = params[:user][:card_token].present? ? current_user.add_token_to_user(params[:user][:card_token]) : [true]
      if token_res.first
        @platform_acct = User.get_platform_acct_obj
        merchant_customer = MerchantCustomer.find_by(customer_id: current_user.id, merchant_id: @platform_acct.id)
        saas_sub = Subscription.new(plan_id: get_plan_id, merchant_customer_id:  merchant_customer.id)
        return saas_sub.create_subscription({ team: @platform_acct })
      end
      token_res
    rescue StandardError => e
      [false]
    end
  end

  def get_plan_id
    Plan.find_by(name: params[:plan][:name], merchant_id: @platform_acct.id, status: 1)
  end

  def after_update_path_for(resource)
    check_user_redirect || root_path
  end

  def after_sign_up_path_for(resource)
    check_user_redirect || root_path
  end

  def set_update_flash_messages(msg = '')
    page_params = { add_profile_info: {
                                        success: 'profile updated',
                                        error: resource.errors.full_messages,
                                        profile_info: true
                                      },
                    add_subscription: {
                                        success: 'Subscription added',
                                        error: msg,
                                        subscription: true
                                      },
                    add_rhombus_number: {
                                          success: 'Rhombus number added',
                                          error: 'Something went wrong. We were unable to provision a number for you. A member of our support team will contact you shortly.',
                                          rhombus_number: true
                                        },
                    add_card_info: {
                                    success: 'Card info added',
                                    error: msg,
                                    card_info: true
                                   },
                    update_billing_info: {
                                          success: 'Billing Info updated',
                                          error: msg,
                                          billing_info: true
                                        },
                    account_settings: {
                                        success: 'account updated',
                                        error: resource.errors.full_messages,
                                        account_settings: true
                                      },
                    business_settings: {
                                        success: 'account updated',
                                        business_settings: true,
                                        error: resource.errors.full_messages
                                       }
                  }
    page_params[params[:page_params].to_sym]
  end

  def setting_pages_present?
    set_update_flash_messages[:business_settings].present? || set_update_flash_messages[:billing_info].present? || set_update_flash_messages[:account_settings]
  end

  def previous_url
    request.referrer || root_path
  end

  def save_resource
    begin
      resource.save
    rescue ActiveRecord::RecordNotUnique
      resource.errors.add(:phone_number, "is already in use") if $!.message.include?('index_users_on_phone_number')
    end
  end

  def update_resource(resource, user_params)
    begin
      if set_update_flash_messages[:account_settings].present?
        resource.update_with_password(user_params)
      else
        resource.update_without_password(user_params)
      end
    rescue ActiveRecord::RecordNotUnique
      resource.errors.add(:phone_number, "is already in use") if $!.message.include?('index_users_on_phone_number')
      false
    end
  end
end
