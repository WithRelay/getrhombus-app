class RegistrationsController < Devise::RegistrationsController

  include AdditionalUserActions
  inlcude DashboardNotification
  before_action :set_notifications, only: [:billing_information, :account_setting, :business_setting]

  def update
    if params[:add_profile_info].present? && current_user.is_merchant?
    else
      set_captured_payment_session
      @re = (params[:user][:card_token].present?) ? current_user.add_token_to_user(params[:user][:card_token]) : [true]

=begin
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

    end
   
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

  #### needs better error handling
  def create_saas_subscription
    if params[:plan].present?
      merchant_customer = MerchantCustomer.find_by(stripe_customer_id: @re[1].id)
      saas_subscription = Subscription.new(plan_id: get_plan_id, merchant_customer_id:  merchant_customer.id)
      saas_subscription.create_subscription({ team: current_user })
    else
      [true]
    end
  end

  def get_plan_id
    plan = Plan.find_by(name:params[:plan][:name], merchant_id: User.get_platform_acct_obj.id)
    plan.id if plan
  end

  def after_update_path_for(resource)
    user_path(resource)
  end

  def after_sign_up_path_for(resource)
    return check_user_redirect
  end

end
