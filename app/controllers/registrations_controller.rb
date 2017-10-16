class RegistrationsController < Devise::RegistrationsController

  include AdditionalUserActions
  include CheckUserProfile

  def update
    self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)
    #prev_unconfirmed_email = resource.unconfirmed_email if resource.respond_to?(:unconfirmed_email)

    message = check_params_with_update
    email_changed = set_update_flash_messages[:account_settings] && params[:user][:email] != current_user.email
    url = request.referrer if setting_pages_present?
    set_flash_message = set_update_flash_messages(message)
    
    yield resource if block_given?

    if message.blank? && update_resource(resource, account_update_params)
      update_stripe_email if email_changed

      # flash_key = update_needs_confirmation?(resource, prev_unconfirmed_email) ? :update_needs_confirmation : :updated
      # set_flash_message :notice, flash_key
      flash[:notice] = set_flash_message[:success] if is_flashing_format?
      bypass_sign_in resource, scope: resource_name

      redirect_to url || after_update_path_for(resource)
    else
      flash[:error] = message.is_a?(Stripe::InvalidRequestError) ? set_flash_message[:error].message : set_flash_message[:error]

      clean_up_passwords resource
      set_minimum_password_length
      redirect_to previous_url
    end
  end

  def create
    build_resource(sign_up_params)
    save_resource
    yield resource if block_given?
    if resource.persisted?
      sign_up(resource_name, resource)
      add_to_merchant_customer_and_referrer_and_fb_cred
      respond_with resource, location: after_sign_up_path_for(resource)
    else
      flash[:error] = resource.errors.full_messages
      clean_up_passwords resource
      set_minimum_password_length
      render :new
    end
  end

  def update_stripe_email
    StripeManagedAccountService.new(current_user).update_account_email if resource.bank_accounts.present?
  end

  def check_params_with_update
    msg = nil

    begin
      if set_update_flash_messages[:subscription] && current_user.is_merchant?
        subscription = create_saas_subscription
        msg = (subscription.third ? subscription.third : "We are unable to start a subscription for you") unless subscription.first
      elsif set_update_flash_messages[:rhombus_number] && current_user.is_merchant?
        unless current_user.buy_number(params['user'])
          msg = 'Something went wrong. We were unable to provision a number for you. A member of our support team will contact you shortly.'
        end
      elsif set_update_flash_messages[:card_info] || set_update_flash_messages[:billing_info]
        if current_user.is_customer? && set_update_flash_messages[:card_info]
          session[:msg_id] = params[:user][:msg_id]
          session[:channel] = params[:user][:channel]
        end
        add_token = current_user.add_token_for_user(params[:user][:card_token])
        msg = (add_token.third ? add_token.third : "We are unable to add your card to your profile.") unless add_token.first
      end
    rescue StandardError => exception
      ExceptionNotifier.notify_exception(exception, env: request.env, data: { message: "In check_params_with_update" })
      msg = "Something went wrong"
    end
    
    return msg
  end

  def auto_recharge
    if params['user']['auto_reload'] == '1'
      auto_reload_amt = params['user']['auto_reload_amt']
      current_user.update(auto_reload_amt: auto_reload_amt, auto_reload: true)
      flash[:notice] = "Auto recharge enabled with $#{Toolbox::Decimal.cents_to_int_or_2dp(auto_reload_amt)}"
    else
      current_user.update(auto_reload: false)
      flash[:notice] = "Auto recharge disabled"
    end
    redirect_to user_sms_usage_path
  end

  def deactivate
    saas_sub = current_user.get_saas_subscription
    if (saas_sub && saas_sub.cancel_subscription(true)) || saas_sub.nil?
      flash[:notice] = 'Your account is deactivated'
    else
      flash[:error] = 'Something went wrong'
    end
    redirect_to user_account_settings_path
  end

  protected

  def create_saas_subscription
    begin
      # or you can check if the selected plan is the free plan
      token_res = params[:user][:card_token].present? ? current_user.add_token_for_user(params[:user][:card_token]) : [true]
      if token_res.first
        current_user.save # update resource changes so far
        @platform_acct = User.get_platform_acct_obj
        merchant_customer = MerchantCustomer.find_by(customer_id: current_user.id, merchant_id: @platform_acct.id)
        saas_sub = Subscription.new(plan_id: get_plan_id, merchant_customer_id:  merchant_customer.id)
        return saas_sub.create_subscription({ team: @platform_acct })
      end
      token_res
    rescue StandardError => exception
      ExceptionNotifier.notify_exception(exception, env: request.env, data: { message: "In create_saas_subscription" })
      [false]
    end
  end

  def get_plan_id
    Plan.find_by(id: params[:plan][:id], status: 1).try(:id)
  end

  def after_sign_up_path_for(resource)
    check_user_redirect || root_path
  end

  def after_update_path_for(resource)
    check_user_redirect || root_path
  end

  def set_update_flash_messages(msg = '')
    page_params = { add_profile_info: {
                                        success: 'Profile created',
                                        error: resource.errors.full_messages,
                                        profile_info: true
                                      },
                    add_subscription: {
                                        success: 'Subscription added',
                                        error: msg,
                                        subscription: true
                                      },
                    add_rhombus_number: {
                                          success: 'Relay number added',
                                          error: 'Something went wrong. We were unable to provision a number for you. A member of our support team will contact you shortly.',
                                          rhombus_number: true
                                        },
                    add_card_info: {
                                    success: 'Card info added',
                                    error: msg,
                                    card_info: true
                                   },
                    update_billing_info: {
                                          success: 'Billing info updated',
                                          error: msg,
                                          billing_info: true
                                        },
                    account_settings: {
                                        success: 'Account updated',
                                        error: resource.errors.full_messages,
                                        account_settings: true
                                      },
                    business_settings: {
                                        success: 'Account updated',
                                        error: resource.errors.full_messages,
                                        business_settings: true,
                                       }
                  }
    page_params[params[:page_params].to_sym]
  end

  def setting_pages_present?
    set_update_flash_messages[:business_settings] || set_update_flash_messages[:billing_info] || set_update_flash_messages[:account_settings]
  end

  def previous_url
    request.referrer || root_path
  end

  def save_resource
    begin
      set_referrer_source
      resource.save
    rescue ActiveRecord::RecordNotUnique
      resource.errors.add(:phone_number, "is already in use") if $!.message.include?('index_users_on_phone_number')
    end
  end

  def update_resource(resource, user_params)
    begin
      if set_update_flash_messages[:account_settings]
        resource.update_with_password(user_params)
      else
        resource.update_without_password(user_params)
      end
    rescue ActiveRecord::RecordNotUnique
      resource.errors.add(:phone_number, "is already in use") if $!.message.include?('index_users_on_phone_number')
      false
    end
  end

  def set_referrer_source
    if params[:user][:referrer_uid].present?
      merchant = User.find_by(relay_uid: params[:user][:referrer_uid])        
      self.resource.customer_source = { id: merchant.id, method: 'referred' } if merchant
    end
  end

end