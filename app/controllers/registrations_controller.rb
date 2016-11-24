class RegistrationsController < Devise::RegistrationsController

  include AdditionalUserActions

  def update
    set_captured_payment_session
    # create merchant_customer
    if current_user.user_level == 1
      # create merchant_customer one time for merchant with merchant id
      current_user.merchant.create()
    else
      current_user.customer.create() if current_user.customer.blank?
    end

    re = PaymentService.add_token_to_stripe_customer(current_user, account_update_params)
      
    if re
      if current_user.update_without_password(devise_parameter_sanitizer.sanitize(:account_update))
        set_flash_message :notice, :updated
        # Sign in the current user bypassing validation in case his password changed
        sign_in current_user, :bypass => true
        respond_with resource, :location => after_update_path_for(resource)
        #redirect_to after_update_path_for(current_user)
      else
        clean_up_passwords resource
        #render "edit", notice: "We were unable to update your information"
        redirect_to build_user_link, flash: { error: "We were unable to update your information. Please retry." }
      end
    else
      clean_up_passwords resource
      #render "edit", notice: "We were unable to update your card information"
      redirect_to build_user_link , flash: { error: "We were unable to update your card information. Please check the details entered." }
    end
  end 


  def create
    set_captured_payment_session
    super
  end

  protected

  def after_update_path_for(resource)
    user_path(resource)
  end

  def after_sign_up_path_for(resource)
    user_path(resource)
  end

end
