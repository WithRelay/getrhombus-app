class MessagesController < ApplicationController

	require "uri"

	def index
		message = Message.new
		#@uri = message.balanced_associate_token_with_user
		#@uri = message.nexmo_search_and_buy_number("US")
	end

	def receive_delivery_report
		@message = Message.new
		@message.text = params[:scts]
		@message.save
		#render status: 200      # Probably no point to this so commented
	end
 
	def receive_text_message
		text = params[:text].strip
		if text.chr == URI.decode("%C2%A4") and is_number(text.split(/, */, 2).first.gsub(/\s+/, "")[1..-1])
			@message = Message.new
			@message.nexmo_send_text_message(params[:msisdn])
			#@url = "yea"
		elsif text.downcase.gsub(/\s+/, "") == "signup" || text.downcase.gsub(/\s+/, "") == "sign-up"
			@message = Message.new
			@message.nexmo_send_signup_text(params[:msisdn])
		end #throw an error???

		#render status: 200      # Probably no point to this so commented
		# rails already unescapes params #uri = URI.unescape(request.original_url.to_s)
		# Code above can be more efficient
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
