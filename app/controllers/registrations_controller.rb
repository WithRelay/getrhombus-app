class RegistrationsController < Devise::RegistrationsController

  include AdditionalUserActions
  include DashboardNotification

  before_action :set_notifications, only: [:billing_information, :account_settings, :business_settings]

  def update
    self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)

    page_params = set_update_flash_messages[params[:page_params].to_sym]

    check_params_with_update(page_params)

    url = request.referrer if page_params[:billing_info].present?

    prev_unconfirmed_email = resource.unconfirmed_email if resource.respond_to?(:unconfirmed_email)

    resource_updated = update_resource(resource, account_update_params)
    yield resource if block_given?
    if resource_updated
      update_stripe_email if page_params[:account_settings].present?
      # flash_key = update_needs_confirmation?(resource, prev_unconfirmed_email) ? :update_needs_confirmation : :updated
      # set_flash_message :notice, flash_key
      flash[:notice] = page_params[:success] if is_flashing_format?
      bypass_sign_in resource, scope: resource_name
      redirect_to url || after_update_path_for(resource)
    else
      flash[:error] = page_params[:error]
      clean_up_passwords resource
      set_minimum_password_length
      redirect_to previous_url
    end
  end

  def create
    set_captured_payment_session
    @user = User.new(params[:sign_up])
    if @user.save
      redirect_to user_path(@user)
    else
      flash[:error] = resource.errors.full_messages if resource.errors.full_messages.present?
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

  def check_params_with_update(page_params)
    if page_params[:subscription].present? && current_user.is_merchant?
      create_saas_subscription
    elsif page_params[:rhombus_number].present? && current_user.is_merchant?
      current_user.buy_number(params)
    elsif page_params[:card_info].present? && current_user.is_customer?
      set_captured_payment_session
      current_user.add_token_to_user(params[:user][:card_token])
    elsif page_params[:billing_info].present?
      current_user.add_token_to_user(params[:user][:card_token])
    end
  end

  def business_settings; end

  def add_rhombus_number; end

  def add_subscription; end

  def add_card_info; end


  protected

  def create_saas_subscription
    begin
      token_res = (params[:user][:card_token].present?) ? current_user.add_token_to_user(params[:user][:card_token]) : [true]
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

  def set_update_flash_messages
    { add_profile_info: {
                          success: 'profile updated',
                          error: 'Unable to update your profile',
                          profile_info: true
                        },
      add_subscription: {
                          success: 'Subscription added',
                          error: 'We are unable to start a subscription for you',
                          subscription: true
                        },
      add_rhombus_number: {
                            success: 'We are unable to provision a number for you',
                            error: 'Rhombus number added',
                            rhombus_number: true
                          },
      add_card_info: {
                      success: 'Card info added',
                      error: 'We are unable to add your card to your profile.',
                      card_info: true
                     },
      update_billing_info: {
                            success: 'Billing Info updated',
                            error: 'We are unable to add your card to your profile.',
                            billing_info: true
                          },
      account_settings: {
                          success: 'account updated',
                          error: 'We are unable to update account. Please try again',
                          account_settings: true
                        },
      business_settings: {
                          success: 'account updated',
                          business_settings: true,
                          error: 'We are unable to update business settings. Please try again'
                         }
    }
  end

  def previous_url
    request.referrer || root_path
  end

  def update_resource(resource, user_params)
    if user_params.keys.include?('current_password')
      resource.update_with_password(user_params)
    else
      resource.update_without_password(user_params)
    end
  end
end
