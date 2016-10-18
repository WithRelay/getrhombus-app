class LinkFbAccountsController < ApplicationController
  def link_facebook
    @params = params
  end

  def redirect
    @params = params
    user = User.find_by_email(@params[:email])
    if user && user.valid_password?(@params[:password])
      redirect_to @params[:redirect_uri]
    else
      redirect_to link_facebook_path(@params), flash: { :error => "Invalid email/password" }
    end
  end

end