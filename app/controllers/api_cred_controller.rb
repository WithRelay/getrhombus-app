class ApiCredController < ApplicationController
  include DashboardNotification

  before_action :set_notifications, except: [:generate]
  def generate
  end
end

