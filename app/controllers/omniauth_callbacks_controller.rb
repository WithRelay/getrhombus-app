class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  protect_from_forgery
  require 'pp'

  def twitter
    # raise request.env["omniauth.auth"].to_yaml
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

  def facebook
    if current_user && current_user.user_level == 1
      if FbCred.from_omniauth(request.env["omniauth.auth"], current_user.id) == true
        FbPage.store_page(current_user)
        redirect_to user_fb_pages_path(current_user)
        set_flash_message(:notice, :success, :kind => "Facebook") if is_navigational_format?
        return
      end
      redirect_to user_path(current_user), alert: "We were unable to connect your account to Facebook account. Please try again"
    else
      redirect_to user_path(current_user), alert: "You cannot connect your Facebook account."
    end
  end

  def failure
    redirect_to user_path(current_user), alert: "We were unable to connect your account. Please try again"
  end

end