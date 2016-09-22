class RegistrationsController < Devise::RegistrationsController

  include AdditionalUserActions

  def update  
    set_captured_payment_session    
    re = current_user.add_token_to_stripe_customer(account_update_params)
      
    if re
      if current_user.update_without_password(devise_parameter_sanitizer.sanitize(:account_update))
        set_flash_message :notice, :updated
        # Sign in the current user bypassing validation in case his password changed
        sign_in current_user, :bypass => true
        respond_with resource, :location => after_update_path_for(resource) #redirect_to after_update_path_for(current_user)
      else
        clean_up_passwords resource
        #render "edit", notice: "We were unable to update your information"
        redirect_to build_user_link, notice: "We were unable to update your information. Please retry."
      end
    else
      clean_up_passwords resource
      #render "edit", notice: "We were unable to update your card information"
      redirect_to build_user_link , notice: "We were unable to update your card information. Please check the details entered."
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