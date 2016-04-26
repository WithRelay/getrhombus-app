class OmniauthCallbacksController < Devise::OmniauthCallbacksController

  def stripe_connect
    # raise request.env["omniauth.auth"].to_yaml
    if current_user && current_user.user_level == 1
      if current_user.from_omniauth(request.env["omniauth.auth"]) == true
        redirect_to user_path(current_user)
        set_flash_message(:notice, :success, :kind => "Stripe Connect") if is_navigational_format?
        return
      end
      redirect_to user_path(current_user), alert: "We were unable to connect your account to Stripe. Please try again"
    else
      redirect_to user_path(current_user), alert: "You cannot connect your Stripe Connect."
    end
  end

  def twitter
    if current_user && current_user.user_level == 1
      if TwitterCred.from_omniauth(request.env["omniauth.auth"], current_user.id) == true
        redirect_to user_path(current_user)
        set_flash_message(:notice, :success, :kind => "Twitter") if is_navigational_format?
        return
      end
      redirect_to user_path(current_user), alert: "We were unable to connect your account to Twitter. Please try again"
    else
      redirect_to user_path(current_user), alert: "You cannot connect your Twitter account."
    end
  end

  def failure
    redirect_to user_path(current_user), alert: "We were unable to connect your account. Please try again"
  end

end