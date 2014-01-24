class MessagesController < ApplicationController

	require "uri"

	def index
		message = Message.new
		#@uri = message.balanced_associate_token_with_user
		#@uri = message.nexmo_search_and_buy_number("US")
		#@uri = message.nexmo_send_text_message(<redacted_phone_number>,<redacted_phone_number>, "yes")
		@uri = message.nexmo_search_and_buy_number("US")
	end

	def receive_delivery_report
		# Do a test here like below
		@message = Message.new
		@message.text = params[:scts]
		
	end
 


	def receive_text_message
		#params[:to] = "<redacted_phone_number>"
		#params[:msisdn] = "<redacted_phone_number>" #"<redacted_phone_number>"

		if params[:text] != ""        				# Ensure there is a text query string
			text = params[:text].strip
			amount = (text.split(/, */, 2).first.gsub(/\s+/, "")[1..-1])
			# for making payments
			if text.chr == "$" || text.chr == URI.decode("%C2%A4") and is_number?(amount)
				# to cents per Balanced   
				amount = ((amount.to_f.round(2).abs)*100).to_i
				if amount >= 50 and amount <= 1500000
					##### Save message
					###### Add payment logic here
					#@url = request.original_url
					@message = Message.new
					@message.save_text(text: params[:text], sure: "me")
					@message.nexmo_send_text_message(params[:to], params[:msisdn], "we sent payment")
				elsif amount > 1500000
					##### Save message
					@message = Message.new
					@message.save_text(text: params[:text], sure: "me")
					@message.nexmo_send_text_message(params[:to], params[:msisdn], "Sorry, we are unable to make payments above 15,000 dollars :(. But you can send in smaller amounts. Thanks!")
					##### Save message
				else
					##### Save message
					@message = Message.new
					@message.nexmo_send_text_message(params[:to], 
						params[:msisdn], "Sorry, we are unable to make payments below 50 cents. :(")
					######## Save message
				end	
			# for signing up
			elsif text.downcase.gsub(/\s+/, "") == "signup" || text.downcase.gsub(/\s+/, "") == "sign-up"
				##### Save message
				@message = Message.new
				@message.nexmo_send_text_message(params[:to], 
					params[:msisdn], "Welcome to rhombus! Save this number to your phone for future payments. Follow the link to complete your signup: www.getrhombus.com/signup?num=#{params[:msisdn]}")
				######## Save message
			else 	# for messages we cant parse sucessfully
				##### Save message
				@message = Message.new
				@message.nexmo_send_text_message(params[:to], 
					params[:msisdn], 'We did not understand your text message. You can signup by texting "signup" or make payments by texting "amount, description". Thanks!')
				######## Save message
			end
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

    # As the name implies
    def is_number?(var)
  	   	true if Float(var) rescue false
	end

end
