class MessagesController < ApplicationController

	require 'uri'

	def index
	end
 
	def send_text_message
		url = URI.encode_www_form([["api_key", "0ed6ecb8"],
					["api_secret", "b4f769d8"],
					["from", "<redacted_phone_number>"],
					["to", "<redacted_phone_number>"],
					["text", "are u eddy?"],

				])
		@response = HTTParty.post('https://rest.nexmo.com/sms/json?'+ url, :headers => {"Content-Type" => "application/x-www-form-urlencoded"} )
	end

	def receive_text_message
		if params[:text]
			@message = Message.new
			@message.text = params[:text]
			@message.save
			render status: 200
		end
	end


	private
    # Use callbacks to share common setup or constraints between actions.
    def set_message
      @message = Message.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def message_params
      params.require(:message).permit(:text)
    end


end
