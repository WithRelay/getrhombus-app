
class RegistrationsController < Devise::RegistrationsController

	def update	
    response = ""
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
      		redirect_to "/profile", notice: "We were unable to update your information. Please retry."
    	end
    else
    	clean_up_passwords resource
      	#render "edit", notice: "We were unable to update your card information"
      	redirect_to "/profile", notice: "We were unable to update your card information. Please check the details entered."
    end
	end	

	# pulled from Devise source code. see additions for comparisons
	def create
    build_resource(sign_up_params)

    resource.save
    yield resource if block_given?
    if resource.persisted?
      if resource.active_for_authentication?
        set_flash_message :notice, :signed_up if is_flashing_format?
        sign_up(resource_name, resource)
        # added this line
        respond_with resource, location: after_sign_up_path_for(resource, params[:user][:captured_amt], 
        				params[:user][:referrer_num], params[:user][:msg_id])
      else
        set_flash_message :notice, :"signed_up_but_#{resource.inactive_message}" if is_flashing_format?
        expire_data_after_sign_in!
        respond_with resource, location: after_inactive_sign_up_path_for(resource)
      end
    else
      clean_up_passwords resource
      set_minimum_password_length
      respond_with resource
    end
	end

  protected

  def after_update_path_for(resource)
    user_path(resource)
  end

  def after_sign_up_path_for(resource, amt=nil, referrer_num=nil, msg_id=nil)
 		user_path(resource, amt: amt, referrer_num: referrer_num, msg_id: msg_id)
	end
end