class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  protect_from_forgery
  before_action :check_user_present

  def twitter
    if current_user.is_merchant?
      if TwitterCred.from_omniauth(request.env["omniauth.auth"], current_user.id) == true
        redirect_to integrations_user_path(current_user)
        set_flash_message(:notice, :success, :kind => "Twitter") if is_navigational_format?
        return
      end
      redirect_to integrations_user_path(current_user), alert: "We were unable to connect your account to Twitter. Please try again"
    else
      redirect_to integrations_user_path(current_user), alert: "You cannot connect your Twitter account."
    end
  end

  def facebook
    if current_user && current_user.is_merchant?
      if FbCred.from_omniauth(request.env["omniauth.auth"], current_user.id) == true
        FbPage.store_page(current_user)
        redirect_to user_fb_pages_path(current_user), flash: { notice: "You have connected Messenger to Rhombus" }
        return
      end
      redirect_to user_path(current_user), flash: { error: "We were unable to connect your account to Facebook account. Please try again" }
    else
      redirect_to user_path(current_user), flash: { error: "You cannot connect your Facebook account." }
    end
  end

  def failure
    redirect_to user_path(current_user), flash: { error: "We were unable to connect your account. Please try again" }
  end

  private 

  def check_user_present
    unless current_user.present?
      redirect_to signin_path
    end
  end

end