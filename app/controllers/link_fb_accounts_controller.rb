class LinkFbAccountsController < ApplicationController
  protect_from_forgery with: :exception

  def link_facebook
    @params = params
  end

  def redirect
    @params = params
    user = User.find_by_email(@params[:email])
    if user && user.valid_password?(@params[:password])
      FacebookMessengerService.update_user_fb_cred(@params)
      url = @params[:redirect_uri] + '&authorization_code=' + @params[:authenticity_token]
      redirect_to url
    else
      redirect_to link_facebook_path(@params), flash: { :error => "Invalid email or password" }
    end
  end
end
