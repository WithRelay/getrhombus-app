class ApiCredsController < ApplicationController
  include DashboardNotification
  before_action :set_notifications

  def show
    @api_cred = current_user.api_cred
  end
end

