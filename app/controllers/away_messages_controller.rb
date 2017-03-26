class AwayMessagesController < ApplicationController

  include DashboardNotification
  before_action :set_notifications

  def index
    @away_message = current_user.away_messages.build
  end
end
