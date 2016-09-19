
class RegistrationsController < Devise::RegistrationsController

<<<<<<< HEAD
  include AdditionalUserActions

	def update	
    set_captured_payment_session
    
    if current_user.user_level == 0
      response = current_user.add_token_to_stripe_customer(account_update_params)
    else
      response = current_user.update_merchant_account(account_update_params)
    end

   	if response == true
    	if current_user.update_without_password(devise_parameter_sanitizer.sanitize(:account_update))
    		set_flash_message :notice, :updated
    		# Sign in the current user bypassing validation in case his password changed
    		sign_in current_user, :bypass => true
    		respond_with resource, :location => after_update_path_for(resource)	#redirect_to after_update_path_for(current_user)
    	else
    		clean_up_passwords resource
    		#render "edit", notice: "We were unable to update your information"
    		redirect_to build_user_link, notice: "We were unable to update your information. Please retry."
=======
	def update	   	
   	# @user already current_user
   	response = current_user.add_token_to_stripe_customer(account_update_params)
   	if response[0] == true
    	if current_user.update_with_password(devise_parameter_sanitizer.sanitize(:account_update))
        notify_new_customer if response[1] == "new_customer"
      	set_flash_message :notice, :updated
      	# Sign in the current user bypassing validation in case his password changed
      	sign_in current_user, :bypass => true
      	respond_with resource, :location => after_update_path_for(resource)	#redirect_to after_update_path_for(current_user)
    	else
      	clean_up_passwords resource
      	#render "edit", notice: "We were unable to update your information"
      	redirect_to edit_user_registration_path, notice: "We were unable to update your information"
>>>>>>> f63f52b9b2dd659ebe2b0707f6a21db258a7113e
    	end
    else
    	clean_up_passwords resource
      #render "edit", notice: "We were unable to update your card information"
<<<<<<< HEAD
      redirect_to build_user_link , notice: "We were unable to update your card information. Please check the details entered."
    end
	end	
=======
      redirect_to edit_user_registration_path, notice: "We were unable to update your card information. Please check the details entered."
    end
  end	
>>>>>>> f63f52b9b2dd659ebe2b0707f6a21db258a7113e


  def create
    set_captured_payment_session
    super
  end

  protected

<<<<<<< HEAD
  def after_update_path_for(resource)
    user_path(resource)
  end

  def after_sign_up_path_for(resource)
 		user_path(resource)
	end

=======
    def after_update_path_for(resource)
      user_path(resource)
    end

    def notify_new_customer
      owner = User.find_by(email: Rails.application.secrets.team_email)
      @message = Message.new
      unless current_user.referrer_num.blank?
        text = "You're all set! To send us a payment, just text back the amount and description. Ex: $20 for donuts."
        @message.send_and_save_message(23, current_user.referrer_num, current_user.phone_number, text)
      else
        text = "You're all set! To send a payment to any business on Rhombus, just text the amount and description to their Rhombus phone number. Ex: $5 for donuts."
        @message.send_and_save_message(23, owner.rhombus_number, current_user.phone_number, text)
      end
    end
>>>>>>> f63f52b9b2dd659ebe2b0707f6a21db258a7113e
end