class Message < ActiveRecord::Base

	belongs_to :txn, :foreign_key => :transaction_id, :class_name => :Transaction
	#belongs_to :user, counter_cache: true
	
	# For sending all text messages
	def send_and_save_message(msg_code, from, to, message)		
		# save the outbound message
		client_ref = self.save_text(message_code: msg_code, from: from, to: to, text: message, unread: false, status_report_req: 1)

		response = TextingService.send_sms(from, to, client_ref, message)		
		# check response		
		if response.code == 200 and response["messages"].first["status"] == "0"		
			# Fetch the saved outbound message and attach nexmo's response to it
			@message = Message.find_by(id: response['messages'].first["client-ref"])
			@message.save_text(status: response['messages'].first['status'], messageId: response['messages'].first['messageId'],
				client_ref: response['messages'].first['client-ref'], message_price: response['messages'].first['message-price'], 
				network_code: response['messages'].first['network'])
		else			
			# Notify marketplace owner of failure
			#(dump, from, to, message)
			Notification.text_failure_notification(response["messages"].first, from, to, message).deliver_now
			#EmailingService.text_failure_notification(response["messages"].first, from, to, message)
			return
		end
	end
	
	# for saving any text received or sent
	def save_text(options = {})

		self.text = options[:text] if options[:text]

		if options[:from]
			# Attached the phone number and user id
			self.from = options[:from]
			self.user_id_from = User.find_by(rhombus_number: "#{options[:from]}").id rescue 0
			# when guests message us
			if self.user_id_from == 0
       			self.user_id_from = User.find_by(phone_number: "#{options[:from]}").id rescue 0
			end
		end

		if options[:to]
			# Attached the phone number and user id
			self.to = options[:to] 
			self.user_id_to =  User.find_by(rhombus_number: "#{options[:to]}").id rescue 0
			# when we message guests
			if self.user_id_to == 0
        		self.user_id_to =  User.find_by(phone_number: "#{options[:to]}").id rescue 0
			end
		end
		
		self.network_code = options[:network_code] if options[:network_code]
		self.messageId = options[:messageId] if options[:messageId]
		self.message_timestamp = options[:message_timestamp] if options[:message_timestamp]
		#self.type = options[:type] if options[:type]
		self.status_report_req = options[:status_report_req] if options[:status_report_req]
		self.message_price = options[:message_price] if options[:message_price]
		self.scts = options[:scts] if options[:scts]
		self.client_ref = options[:client_ref] if options[:client_ref]
		self.status = options[:status] if options[:status]
		self.status_delivery = options[:status_delivery] if options[:status_delivery]
		self.err_code = options[:err_code] if options[:err_code]
		self.error_text = options[:error_text] if options[:error_text]
		self.message_code = options[:message_code] if options[:message_code]		
		self.transaction_id = options[:transaction_id] if options[:transaction_id]
		self.unread = options[:unread] unless options[:unread].nil?
		self.save
		return self.id
		#if @message.save
		#	return 200
		#else
			#return 500
		#end
		#return options[:sure]
	end
	
	# Returns hash with the last "num_messages" messages that the given user has sent to the given merchant
  def self.get_user_messages_by_merchant(user_id, merchant_id, num_messages)
    messages = Message.select('`messages`.`user_id_from`,`messages`.`text`,`messages`.`unread`,`messages`.`created_at`,`users`.`user_level`')
                   .joins('INNER JOIN `users` ON (`users`.`id` = `messages`.`user_id_from`)')
                   .where('(`messages`.`user_id_from` = ? AND `messages`.`user_id_to` = ?) OR (`messages`.`user_id_from` = ? AND `messages`.`user_id_to` = ?)', user_id, merchant_id, merchant_id, user_id)
                   .order('`messages`.`created_at` DESC').limit(num_messages)
    latest_messages = Array.new
    messages.reverse.each do |message|
      latest_messages.push({
        :user_id => message.user_id_from,
        :user_level => message.user_level,
        :image_url => message.user_level == 0 ? ActionController::Base.helpers.asset_path('user_icon_50x50.png') : ActionController::Base.helpers.asset_path('rhombus_icon_50x50.png'),
        :text => message.text,
        :ts_day_of_the_week => message.created_at.strftime('%A'),
        :ts_time => message.created_at.strftime('%l:%M %P'),
        :unread => message.unread
      })
    end
    latest_messages
  end
  
  # Marks all user messages sent to a merchant as read
  def self.mark_user_messages_for_merchant_as_read(user_id, merchant_id)
    Message.where('user_id_from = ? AND user_id_to = ? AND unread = ?', user_id, merchant_id, true).update_all(unread: false)
  end

end
