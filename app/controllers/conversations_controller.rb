class ConversationsController < ApplicationController
  include DashboardNotification
  before_action :set_notifications

	def index
    pubnub = Pubnub.new(
      publish_key: Rails.application.secrets.pubnub["publish_key"],
      subscribe_key: Rails.application.secrets.pubnub["subscribe_key"],
      uuid: "uuid-#{current_user.id}"
    )
    pubnub.subscribe(
      channels: ['messaging_' + Rails.env + '_' + current_user.id.to_s],
      with_presence: true
    )
	end

  def receive_voice_twilio
    render xml: TextingService.receive_call.to_xml
  end

end
