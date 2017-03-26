class AwayMessagesController < ApplicationController

  include DashboardNotification
  before_action :set_notifications

  def index
  end
end
