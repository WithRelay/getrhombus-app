class ApiCredsController < ApplicationController
  include DashboardNotification
  before_action :set_notifications, only: [:show]
  before_action :set_api_cred

  def show; end

  def update
    if @api_cred.update(webhook_url: params[:api_cred][:webhook_url])
      flash[:notice] = 'Webhook url updated successfully'
    else
      flash[:error] = 'Webhook url could not update'
    end
    redirect_to user_api_cred_path(current_user)
  end

  private

  def set_api_cred
    @api_cred = ApiCred.find_or_create_by(user_id: current_user.id)
  end
end

