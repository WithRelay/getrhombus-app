class LinkFbAccountsController < ApplicationController
  before_action :set_params
  include DashboardNotification
  before_action :set_notifications

  def link_facebook
    page = JSON.parse FacebookMessengerService.get_page_response(params[:account_linking_token])
    @referrer = FbPage.find_by(page_id: page['id']).user.relay_uid
  end

  def redirect
    user = User.find_by_email(@params[:email])
    if user && user.valid_password?(@params[:password])
      FacebookMessengerService.update_user_fb_cred(user, @params)
      url = @params[:redirect_uri] + '&authorization_code=' + @params[:authenticity_token]
      redirect_to url
    else
      redirect_to link_facebook_path(@params), flash: { :error => "Invalid email or password" }
    end
  end

  private
    def set_params
      @params = params
    end
end
