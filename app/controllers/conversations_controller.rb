class ConversationsController < ApplicationController
  include DashboardNotification
  before_action :set_notifications

	def index
	end

  def receive_voice_twilio
    render xml: TextingService.receive_call.to_xml
  end

end
