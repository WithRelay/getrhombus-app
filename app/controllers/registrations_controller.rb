class RegistrationsController < Devise::RegistrationsController

	def update
	    # For Rails 4
	    account_update_params = devise_parameter_sanitizer.for(:account_update)

	    @user = User.find(current_user.id)

		@user.balanced_associate_token_with_customer(account_update_params)


	    if @user.update_with_password(account_update_params)
	      set_flash_message :notice, :updated
	      # Sign in the user bypassing validation in case his password changed
	      sign_in @user, :bypass => true
	      redirect_to after_update_path_for(@user)
	    else
	      render "edit"
	    end
  	end	


  protected

    def after_update_path_for(resource)
      user_path(resource)
    end
end

