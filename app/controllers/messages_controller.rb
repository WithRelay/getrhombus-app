class MessagesController < ApplicationController

	require "uri"

	def index
		message = Message.new
		#@uri = message.balanced_associate_token_with_user
		#@uri = message.nexmo_search_and_buy_number("US")
	end
 
	def receive_text_message
		# rails already unescapes params @url = URI.escape(request.original_url.to_s)
		
		# Code below can be more efficient
		text = params[:text]
		if text.chr == "$" and is_number(text.split(/, */, 2).first.gsub(/\s+/, "")[1..-1])
			@message = Message.new
			@message.nexmo_send_text_message(params[:msisdn])
		elsif text.downcase.gsub(/\s+/, "") == "signup" || text.downcase.gsub(/\s+/, "") == "sign-up"
			@message = Message.new
			@message.nexmo_send_signup_text(params[:msisdn])
		end #throw an error???
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

    def is_number(obj)
  	   obj.to_f.to_s == obj.to_s || obj.to_i.to_s == obj.to_s
	end


end
