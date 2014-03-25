class MessagesController < ApplicationController

	require "uri"
	require 'rack/utils'

	def index
		#@message = Message.new
		#@url = @message.nexmo_send_text_message(1, <redacted_phone_number>, <redacted_phone_number>, "$$$$ yea")
		#@url = @message.nexmo_search_and_buy_number("US")
	end

	def receive_delivery_report
		head :ok, :content_type => 'text/html'		# render :status => 200	
		save_delivery_receipts(request.query_string)
	end

	def receive_text_message
		#params[:to] = "<redacted_phone_number>"
		#params[:msisdn] = "<redacted_phone_number>" 			# "<redacted_phone_number>"
		head :ok, :content_type => 'text/html'		 #render :status => 200						# for nexmo

		if params[:text] != ""        				# Ensure there is a text query string

			text = params[:text].strip
			amount = get_number(text)
			
			if text.chr == "$" || URI.escape(text.chr) == "%C2%A4" and is_number?(amount)	# Ensure text is valid for making payments

				amount = to_cents(amount)

				if amount >= 500 and amount <= 1500000

					begin
						# find the user
						# change this to if statement##################################################
						@user = User.find_by!(phone_number: params[:msisdn])
					rescue
						# if user doesnt exist
						# save in messages and send a response
						save_inbound_text(request.query_string, msg_code = 6)
						@message = Message.new
						@message.nexmo_send_text_message(16, params[:to], params[:msisdn], "Thank you for sending a payment with rhombus. Please follow the link below to create an account, and resend your payment. Thanks! => www.getrhombus.com/signup?num=#{params[:msisdn]}")
						return
					else

						if @user.customer_uri.blank?
							save_inbound_text(request.query_string, msg_code = 7)
							@message = Message.new
							@message.nexmo_send_text_message(17, params[:to], params[:msisdn], "Thank you for sending a payment with rhombus. Please follow the link below to complete your account, and resend your payment. Thanks! => www.getrhombus.com/signin")
						else
=begin
							# if user and uri exist, proceed to payment
							@customer_transaction = Transaction.new

							# could have returned merchant object here...another option to avoid search again in merchant credit call
							debit_data = @customer_transaction.balanced_debit_customer_card(amount, @user, params[:to], text)
							save_inbound_text(request.query_string, msg_code = 1, debit_data[0])
							
							# proceed to send credit to merchant if no error
							if debit_data != "failed"
								@merchant_transaction = Transaction.new
								credit_data = @merchant_transaction.balanced_credit_merchant_bank_account(debit_data, @user, params[:to], text)
								
								if credit_data != "failed"
									# set the merchant transaction id in the customer referenced transaction id
									@customer_transaction.referenced_merchant_transaction_id = credit_data[0]#@merchant_transaction.id
									@customer_transaction.save

									# for cash out, save customer and merchant transaction ids
									@marketplace_transaction = Transaction.new
									@marketplace_transaction.owner_transaction_info(debit_data, credit_data, @user, text)#@merchant_transaction.id, @user, text)
								end
							end	
=end
							@message = Message.new
							# see number 19 for payment system outage
						    @message.nexmo_send_text_message(19, params[:to], params[:msisdn], "Thank you for sending a payment with rhombus. We're currently experiencing a system outage. We will notify you once the outage is resolved. Thanks!")
						end					
					end

				elsif amount > 1500000

					# save in messages and send a response
					save_inbound_text(request.query_string, msg_code = 2)
					@message = Message.new 							
					@message.nexmo_send_text_message(12, params[:to], params[:msisdn], 
						"Sorry, we are unable to make payments above 15,000 dollars :(. But you can send in smaller amounts. Thanks!")
				
				else
					
					# save in messages and send a response
					save_inbound_text(request.query_string, msg_code = 3)
					@message = Message.new 											
					@message.nexmo_send_text_message(13, params[:to], 
						params[:msisdn], "Sorry, we are unable to make payments below 5 dollars. :(")
				
				end	
			# for signing up
			elsif text.downcase.gsub(/\s+/, "") == "signup" || text.downcase.gsub(/\s+/, "") == "sign-up" || text.downcase.gsub(/\s+/, "") == "give" || text.downcase.gsub(/\s+/, "") == "pay"

				# save in messages and send a response
				save_inbound_text(request.query_string, msg_code = 4)
				@message = Message.new 				
				@message.nexmo_send_text_message(14, params[:to], params[:msisdn], 
					"Welcome to rhombus! Save this number to your phone for future payments :). Follow the link to complete your signup: www.getrhombus.com/signup?num=#{params[:msisdn]}")
			
			else 	
				
				# for messages we cant parse sucessfully
				# save in messages
				save_inbound_text(request.query_string, msg_code = 5)
				# until nexmo can give use concatenated messages
				
				@message = Message.new        		
				@message.nexmo_send_text_message(15, params[:to], params[:msisdn], 
					'Sorry we did not understand your text message :(. You can signup by texting "signup" or make payments by texting "amount, description". Thanks!')
			
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
			text: query_hash['text'], message_code: msg_code, transaction_id: transaction_id)
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
				client_ref: query_hash['client-ref'], message_code: 8)
		else
			@message.save_text(status_delivery: query_hash["status"], err_code: query_hash['err-code'],
				scts: query_hash['scts'], message_timestamp: query_hash["message-timestamp"])
		end
	end
end


#if !query_hash.has_key?("network-code")				# Looks like nexmo doesnt always provide this...not sure
	#query_hash['network-code'] = ""
#end