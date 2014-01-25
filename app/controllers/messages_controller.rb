class MessagesController < ApplicationController

	require "uri"
	require 'rack/utils'

	def index
		message = Message.new
		#@uri = message.balanced_associate_token_with_user
		#@uri = message.nexmo_search_and_buy_number("US")
		#@uri = message.nexmo_send_text_message(<redacted_phone_number>,<redacted_phone_number>, "yes")
		@uri = message.nexmo_search_and_buy_number("US")
	end

	def receive_delivery_report
		# Do a test here like below
		#@message = Message.new
		#@message.save_text(text: params[:text], sure: "me")
		
	end
 


	def receive_text_message
		#params[:to] = "<redacted_phone_number>"
		#params[:msisdn] = "<redacted_phone_number>" #"<redacted_phone_number>"
		if params[:text] != ""        				# Ensure there is a text query string
			text = params[:text].strip
			amount = get_number(text)
			# for making payments
			if text.chr == "$" || text.chr == URI.decode("%C2%A4") and is_number?(amount)					
				amount = to_cents(amount)
				if amount >= 50 and amount <= 1500000
					##### Save message
					###### Add payment logic here
					@message = Message.new
					@message.save_text(text: params[:text], sure: "me")
					@message.nexmo_send_text_message(params[:to], params[:msisdn], "we sent payment")
				elsif amount > 1500000
					@message = Message.new
					@message.save_text(text: params[:text], sure: "me")
					@message.nexmo_send_text_message(params[:to], params[:msisdn], "Sorry, we are unable to make payments above 15,000 dollars :(. But you can send in smaller amounts. Thanks!")
				else
					@message = Message.new
					@message.nexmo_send_text_message(params[:to], 
						params[:msisdn], "Sorry, we are unable to make payments below 50 cents. :(")
				end	
			
			elsif text.downcase.gsub(/\s+/, "") == "signup" || text.downcase.gsub(/\s+/, "") == "sign-up"		# for signing up

				query_hash = Rack::Utils.parse_nested_query(request.query_string)     # deal with some weird params from nexmo
				# save text message 
				@message = Message.new
				@message.save_text(type: params[:type], from: params[:msisdn], to: params[:to], 
					network_code: query_hash["network-code"], messageId: params[:messageId], message_timestamp: query_hash["message-timestamp"],
					text: params[:text])
				# send response and save message in model
				@message = Message.new
				@message.nexmo_send_text_message(params[:to], 
					params[:msisdn], "Welcome to rhombus! Save this number to your phone for future payments :). Follow the link to complete your signup: www.getrhombus.com/signup?num=#{params[:msisdn]}")
			
			else 	# for messages we cant parse sucessfully
			
				call_save_text(params, request.query_string)
				# send response and save message in model
				@message = Message.new
				@message.nexmo_send_text_message(params[:to], 
					params[:msisdn], 'Sorry we did not understand your text message :(. You can signup by texting "signup" or make payments by texting "amount, description". Thanks!')
			
			end
		end
	end

	

	private

	def call_save_text(params, query)
		query_hash = Rack::Utils.parse_nested_query(query)     # deal with some weird params from nexmo
		# save text message 
		@message = Message.new
		@message.save_text(type: params[:type], from: params[:msisdn], to: params[:to], 
			network_code: query_hash["network-code"], messageId: params[:messageId], message_timestamp: query_hash["message-timestamp"],
			text: params[:text])
	end
	
    # Use callbacks to share common setup or constraints between actions.
    def set_message
      @message = Message.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def message_params
      params.require(:message).permit(:text)
    end

    # As the name implies
    def is_number?(var)
  	   	true if Float(var) rescue false
	end

	# to cents per Balanced
	def to_cents(var)
		return ((var.to_f.round(2).abs)*100).to_i
	end

	# get the amount for payment
	def get_number(var)
		return (var.split(/, */, 2).first.gsub(/\s+/, "")[1..-1])
	end

end

#if params[:text].length <= 160 			# Ensure it is less than 160 chars

=begin
			else
				@message = Message.new
				@message.nexmo_send_text_message(params[:to], 
					params[:msisdn], "We are sorry, but your text message exceeded 160 characters :(. Please send a shorter message. Thanks!")
				query_hash = Rack::Utils.parse_nested_query(request.query_string)
				@message.save_text(type: params[:type], from: params[:msisdn], to: params[:msisdn], 
					network_code: query_hash["network-code"], messageId: params[:messageId], message_timestamp: query_hash["message-timestamp"],
					text: params[:text])
				
				#@url = @url["text"]
				#@url = #params["network-code"]
			end
=end