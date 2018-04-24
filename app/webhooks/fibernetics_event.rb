class FiberneticsEvent

  def process_event(params)
    # Parameters: {"userId"=>"+<redacted_phone_number>", "signature"=>"203554682", "message"=>"new_messages"}
    @params = params
    @to = params[:userId].gsub('+', '')
    #@merchant = User.includes(:api_cred, :sms_fee).find_by(rhombus_number: @to)
    @number = Number.includes(user: [:sms_fee, :api_cred]).find_by(number: @to)
    @merchant = @number.try(:user)
    get_message if @merchant
  end

  private

=begin
  #<HTTParty::Response:0xb5120b0 
  parsed_response={"response"=>{"status"=>"OK", "last_server_message_id"=>"203556561", 
  "messages"=>{"message"=>
  [{"id"=>"203554682", "to"=>"+<redacted_phone_number>", "from"=>"+<redacted_phone_number>", "body"=>"Hello", "timestamp"=>"2017-10-17 04:16:08.000 UTC"}, 
  {"id"=>"203556560", "to"=>"+<redacted_phone_number>", "from"=>"+<redacted_phone_number>", "body"=>"Yes", "timestamp"=>"2017-10-17 04:41:52.000 UTC"}]
  }}}, 
  @response=#<Net::HTTPOK 200 OK readbody=true>, 
  @headers={"cache-control"=>["private"], "content-length"=>["544"], "content-type"=>["text/xml"], "server"=>["Microsoft-IIS/7.5"], 
  "x-aspnet-version"=>["4.0.30319"], "x-powered-by"=>["ASP.NET"], "date"=>["Tue, 17 Oct 2017 04:41:58 GMT"], "connection"=>["close"]}>
=end

  def get_message
    #re = TextingService.get_sms_fibernetics(@to, @params[:signature].to_i - 1, @merchant.fn_subscriber_id)
    re = TextingService.get_sms_fibernetics(@to, @params[:signature].to_i - 1, @number.fibernetics_subscriber_id)
    if re && re.code == 200 && re['response']['status'] == "OK"
      data = re['response']['messages']['message']
      data = [data] unless data.is_a? Array
      data.each { |m| save_received_message(m) }
    end
  end

  # when message is sent to rhombus
  def save_received_message(data)
    begin
      return if Message.where(message_id: data['id']).exists?

      @phone_number = data['from'].gsub('+', '')
      @timestamp = data['timestamp']
      user = User.find_by(phone_number: @phone_number)      
      num_segments = Message.num_of_segments(data["body"])     
      sms_price = @merchant.sms_fee.inbound_sms 

      @message = Message.create!(
        to: @to,
        from: @phone_number,
        user_id: user.try(:id),
        user_id_to: @merchant.id,
        message_id: data['id'],
        text: data['body'].strip,
        num_segments: num_segments,
        message_timestamp: @timestamp.to_time,
        relay_price: sms_price
      )

      post_message_to_api_user if @merchant.is_api_user? && @merchant.api_cred.webhook_url.present?
      
      # create or add to existing conversation, send to real time service
      if user.present?
        uid, uid_type = user.id, 'user'
        MerchantCustomer.add_or_update_merchant_customer(@merchant, user)
      else
        uid, uid_type = @phone_number, 'phone_number'
        MerchantContact.add_or_update_merchant_contact(@merchant.id, uid, uid_type)
        OpenCnamData.find_record_or_get_intelligence_data(uid)
      end

      Conversation.find_or_create_conversation_for_message_and_publish(@merchant, user, uid_type, uid, @message, true)
      #@merchant.away_message.check_office_hours(@merchant, user, uid_type, uid, "Message")
      MessageParser.new.process_message(@merchant, user, uid, uid_type, @message, 'Message')
      #@merchant.deduct_from_account_balance(sms_price * num_segments) 
       
    rescue ActiveRecord::RecordNotUnique => exception
      ExceptionNotifier.notify_exception(exception, data: { message: "In fibernetics save_received_message record not unique", env: Rails.env, params: @params })
    rescue ActiveRecord::RecordInvalid => exception
      ExceptionNotifier.notify_exception(exception, data: { message: "In fibernetics save_received_message record invalid", env: Rails.env, params: @params })
    rescue StandardError => exception
      ExceptionNotifier.notify_exception(exception, data: { message: "In fibernetics save_received_message", env: Rails.env, params: @params })
    end
  end

  def post_message_to_api_user
    begin
      webhook_url = @merchant.api_cred.webhook_url
      body = { from: @phone_number, to: @to, body: @message.text, timestamp: @timestamp }
      options = { body: body.to_json, headers: { 'Content-Type' => 'application/json' } }
      HTTParty.post(webhook_url, options)
    rescue => exception
      ExceptionNotifier.notify_exception(exception, data: { message: "In post_message_for_api_user standard error", env: Rails.env, params: @params })
    end
  end
end
