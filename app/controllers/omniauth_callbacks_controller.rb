class OmniauthCallbacksController < Devise::OmniauthCallbacksController

  def stripe_connect
    # raise request.env["omniauth.auth"].to_yaml
    @user = current_user.from_omniauth(request.env["omniauth.auth"])
    if @user == true
    	sign_in_and_redirect current_user
        set_flash_message(:notice, :success, :kind => "Stripe Connect") if is_navigational_format?
    else
    	#session["devise.user_attributes"] = @user.attributes
    	redirect_to user_path(current_user), alert: "We were unable to connect your account to Stripe. Please try again"
    end
  end

end