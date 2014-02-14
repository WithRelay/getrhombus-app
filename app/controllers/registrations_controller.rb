
class RegistrationsController < Devise::RegistrationsController

	def update
	    	    
	    @user = User.find(current_user.id)
		@user.balanced_associate_token_with_customer(account_update_params)
	    if @user.update_with_password(devise_parameter_sanitizer.sanitize(:account_update))
	      set_flash_message :notice, :updated
	      # Sign in the user bypassing validation in case his password changed
	      sign_in @user, :bypass => true
	      respond_with resource, :location => after_update_path_for(resource)	#redirect_to after_update_path_for(@user)
	    else
	      clean_up_passwords resource
	      render "edit"
	    end
  	end	


  protected

    def after_update_path_for(resource)
      user_path(resource)
    end
end