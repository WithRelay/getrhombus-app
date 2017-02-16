class RegistrationsController < Devise::RegistrationsController

  include AdditionalUserActions
  include DashboardNotification

  before_action :set_notifications, only: [:billing_information, :account_setting, :business_setting]

  def update
    if params[:add_profile_info].present? && current_user.is_merchant?
      current_user.status = 2
    elsif params[:add_rhombus_number].present? && current_user.is_merchant?
      current_user.status = 3
    elsif params[:add_subscription].present? && current_user.is_merchant?
      current_user.status = 1
      re = create_saas_subscription
      if re.first
        re = current_user.buy_rhombus_number
        msg = "We are unable to provision a number for you" unless re
      else
        msg = re.third ? re.third : "We are unable to start a subscription for you"
      end
    else
      #set_captured_payment_session
      #@re = (params[:user][:card_token].present?) ? current_user.add_token_to_user(params[:user][:card_token]) : [true]
    end

=begin
    if re && re.first

    else

    end


    if @re && @re.first
      sub_res = create_saas_subscription
      if sub_res.first && current_user.update_without_password(devise_parameter_sanitizer.sanitize(:account_update))
        StripeManagedAccountService.new(current_user).update_account_email
        set_flash_message :notice, :updated
        # Sign in the current user bypassing validation in case his password changed
        sign_in current_user, bypass: true
        respond_with resource, location: "/users/#{current_user.id}"
        #redirect_to after_update_path_for(current_user)
      else
        clean_up_passwords resource
        #render "edit", notice: "We were unable to update your information"
        redirect_to "/users/#{current_user.id}", flash: { error: "We were unable to update your information. Please retry." }
      end
    else
      clean_up_passwords resource
      #render "edit", notice: "We were unable to update your card information"
      error_message = (@re && @re.second == 'card_error') ? @re.third :  "We were unable to update your card information. Please check the details entered."
      redirect_to "/users/#{current_user.id}", flash: { error: error_message }
    end
=end

=begin
    if current_user.update_without_password(devise_parameter_sanitizer.sanitize(:account_update))
      set_flash_message :notice, :updated
      # Sign in the current user bypassing validation in case his password changed
      sign_in current_user, bypass: true
      respond_with resource, location: "/users/#{current_user.id}"
      #redirect_to after_update_path_for(current_user)
    else
      clean_up_passwords resource
      #render "edit", notice: "We were unable to update your information"
      redirect_to "/users/#{current_user.id}", flash: { error: "We were unable to update your information. Please retry." }
    end
=end
  end

  def create
    set_captured_payment_session
    super
  end

  def add_profile_info
    @user = current_user
    @user.people = [@user.people.first || Person.new]
  end

  def billing_information; end

  def account_setting; end

  def business_setting; end

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
        saas_subscription = Subscription.new(plan_id: get_plan_id, merchant_customer_id:  merchant_customer.id)
        return saas_subscription.create_subscription({ team: @platform_acct })
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
    user_path(resource)
  end

  def after_sign_up_path_for(resource)
    return check_user_redirect
  end

end
