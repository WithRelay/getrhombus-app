class ConversationsController < ApplicationController

	def index
    puts Conversation.get_open_conversations(current_user.id, params[:page]).to_json
	end

  def receive_voice_twilio
    render xml: TextingService.receive_call.to_xml
  end

end