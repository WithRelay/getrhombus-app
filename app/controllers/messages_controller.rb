class MessagesController < ApplicationController

	require "uri"
	require 'rack/utils'

	def index
		@message = Message.new
		@url = @message.nexmo_send_text_message(<redacted_phone_number>, <redacted_phone_number>, "$$$$ yea")
	end

	def receive_delivery_report
		@message = Message.new
		save_delivery_receipts(request.query_string)		
	end

	def receive_text_message
		params[:to] = "<redacted_phone_number>"#<redacted_phone_number>"
		params[:msisdn] = "<redacted_phone_number>"#"<redacted_phone_number>"
		if params[:text] != ""        				# Ensure there is a text query string

			text = params[:text].strip
			amount = get_number(text)
			
			if text.chr == "$" and is_number?(amount)	# Ensure text is valid for making payments

				amount = to_cents(amount)

				if amount >= 50 and amount <= 1500000

					begin
						# find the user
						@user = User.find_by(phone_number: params[:msisdn])
					rescue
						# if user doesnt exist
						# save in messages and send a response
						save_inbound_text(request.query_string, msg_code = 7)
						@message = Message.new
						@message.nexmo_send_text_message(params[:to], params[:msisdn], "Thank you for sending a payment with rhombus. Please follow the link below to create an account, and resend your payment. Thanks! => www.getrhombus.com/signup?num=#{params[:msisdn]}")
						return
					else

						if @user.customer_uri.blank?
							save_inbound_text(request.query_string, msg_code = 8)
							@message = Message.new
							@message.nexmo_send_text_message(params[:to], params[:msisdn], "Thank you for sending a payment with rhombus. Please follow the link below to complete your account, and resend your payment. Thanks! => www.getrhombus.com/signin")
						else
							# if user and uri exist, proceed to payment
							@customer_transaction = Transaction.new

							# could have returned merchant object here...another option to avoid search again in merchant credit call
							debit_data = @customer_transaction.balanced_debit_customer_card(amount, @user, params[:to], text)
							save_inbound_text(request.query_string, msg_code = 1, debit_data[0])
							
							# proceed to send credit to merchant if no error
							if debit_data != "failed"
								@merchant_transaction = Transaction.new
								@merchant_transaction.balanced_credit_merchant_bank_account(debit_data, @user, params[:to], text)
								
								if @merchant_transaction_id != "failed"
									# set the merchant transaction id in the customer referenced transaction id
									@customer_transaction.referenced_merchant_transaction_id = @merchant_transaction.id
									@customer_transaction.save

									# cash out, and set the customer transaction id and the merchant transaction id
									@marketplace_transaction = Transaction.new
									@marketplace_transaction.balanced_payout_to_marketplace_bank_account(debit_data, @merchant_transaction.id, @user, text)
								end
							end	
						end					
					end

				elsif amount > 1500000

					# save in messages and send a response
					save_inbound_text(request.query_string, msg_code = 2)
					@message = Message.new 							
					@message.nexmo_send_text_message(params[:to], params[:msisdn], 
						"Sorry, we are unable to make payments above 15,000 dollars :(. But you can send in smaller amounts. Thanks!")
				
				else
					
					# save in messages and send a response
					save_inbound_text(request.query_string, msg_code = 3)
					@message = Message.new 											
					@message.nexmo_send_text_message(params[:to], 
						params[:msisdn], "Sorry, we are unable to make payments below 50 cents. :(")
				
				end	
			
			elsif text.downcase.gsub(/\s+/, "") == "signup" || text.downcase.gsub(/\s+/, "") == "sign-up"		# for signing up

				# save in messages and send a response
				save_inbound_text(request.query_string, msg_code = 4)
				@message = Message.new 				
				@message.nexmo_send_text_message(params[:to], params[:msisdn], 
					"Welcome to rhombus! Save this number to your phone for future payments :). Follow the link to complete your signup: www.getrhombus.com/signup?num=#{params[:msisdn]}")
			
			else 	
				
				# for messages we cant parse sucessfully
				# save in messages
				save_inbound_text(request.query_string, msg_code = 5)
				# until nexmo can give use concatenated messages
				
				#@message = Message.new        		
				#@message.nexmo_send_text_message(params[:to], params[:msisdn], 
				#	'Sorry we did not understand your text message :(. You can signup by texting "signup" or make payments by texting "amount, description". Thanks!')
			
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

	# to cents per Balanced
	def to_cents(var)
		return ((var.to_f.round(2).abs)*100).to_i
	end

	# get the amount for payment
	def get_number(var)
		return (var.split(/, */, 2).first.gsub(/\s+/, "")[1..-1])
	end

	# save text message 
	def save_inbound_text(query, msg_code, transaction_id = 0)						# if not for payment, transaction_id = 0
		query_hash = Rack::Utils.parse_nested_query(query)      # deal with some weird params from nexmo
		@message = Message.new 									
		@message.save_text(from: query_hash['msisdn'], to: query_hash['to'], 
			network_code: query_hash["network-code"], messageId: query_hash['messageId'], message_timestamp: query_hash["message-timestamp"],
			text: query_hash['text'], message_code: msg_code, message_type: 2, transaction_id: transaction_id)
	end

	def save_delivery_receipts(query)
		query_hash = Rack::Utils.parse_nested_query(query)      # deal with some weird params from nexmo
		begin
			@message = Message.find_by(id: query_hash["client-ref"]) 
		rescue
			@message = Message.new
			@message.save_text(from: query_hash["to"], network_code: query_hash['network-code'], messageId: query_hash['messageId'], 
				to: query_hash["msisdn"], status_delivery: query_hash["status"], err_code: query_hash['err-code'], message_price: query_hash["price"], 
				scts: query_hash['scts'], message_timestamp: query_hash["message-timestamp"], 
				client_ref: query_hash['client-ref'], message_code: 6, message_type: 3)
		else
			@message.save_text(status_delivery: query_hash["status"], err_code: query_hash['err-code'],
				scts: query_hash['scts'], message_timestamp: query_hash["message-timestamp"], message_code: 6)
		end
	end
end


#if !query_hash.has_key?("network-code")				# Looks like nexmo doesnt always provide this...not sure
	#query_hash['network-code'] = ""
#end