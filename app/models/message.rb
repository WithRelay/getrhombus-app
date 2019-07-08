class Message < ActiveRecord::Base

  # for conversation
  has_many :conversation_refs, as: :textable, dependent: :destroy
  has_many :conversations, through: :conversation_refs

  belongs_to :txn, :foreign_key => :transaction_id, :class_name => :Transaction
  belongs_to :hashtag

  # for image table relation
  has_many :image_refs, as: :imageable, dependent: :destroy
  has_many :images, through: :image_refs

  validates :message_id, uniqueness: true, allow_nil: true

  belongs_to :user

  # For sending and saving all outbound text messages
  def send_and_save_message(merchant, user, from, to, message, media_ary = [])
    begin
      # save message before sending
      user = user.try(:id)
      self.update_attributes(user_id: merchant.id, user_id_to: user, from: from, to: to, text: message)
      sms_price = merchant.sms_fee.outbound_sms
      number = merchant.numbers.find_by(number: from)

      #if merchant.rn_type.present?      # twilio
      if number.number_type.present?      # twilio
        response = TextingService.send_sms(from, to, message, media_ary)
        if response.first
          response = response.second
          num_segments = response.num_segments.to_i
          price = media_ary.blank? ? sms_price : merchant.sms_fee.outbound_mms
          #merchant.deduct_from_account_balance(price * num_segments)
          self.update_attributes(status: response.status, message_id: response.sid, message_timestamp: response.date_updated,
                                  message_price: response.price, error_code: response.error_code, error_text: response.error_message,
                                  price_unit: response.price_unit, num_segments: num_segments, num_media: response.num_media, relay_price: price)
        else
          ExceptionNotifier.notify_exception(StandardError.new, data: { message: "From send_and_save_message, unable to send message", from: from, to: to, text: message, env: Rails.env, response: response })
          false
        end
      #elsif merchant.fn_subscriber_id.present?   #  fibernetics
      elsif number.fibernetics_subscriber_id.present?   #  fibernetics
        response = TextingService.send_sms_fibernetics(from, to, message, number.fibernetics_subscriber_id)
        if response && response.code == 200 && response['response']['status'] == 'OK'
          num_segments = Message.num_of_segments(message)
          merchant.deduct_from_account_balance(sms_price * num_segments)
          self.update_attributes(status: "OK", num_segments: num_segments, relay_price: sms_price)
        else
          ExceptionNotifier.notify_exception(StandardError.new, data: { message: "From send_and_save_message, unable to send message", from: from, to: to, text: message, env: Rails.env, response: response })
          false
        end
      else # nexmo
        response = TextingService.send_sms_nexmo(from, to, message, self.id)
        if response.first && response.second.code == 200 && response.second["messages"].first["status"] == "0"
          response = response.second
          num_segments = response['message-count'].to_i
          #merchant.deduct_from_account_balance(sms_price * num_segments)
          self.update_attributes(status: response['messages'].first['status'], num_segments: num_segments, relay_price: sms_price,
                                  message_id: response['messages'].first['message-id'], error_text: response["error-text"],
                                  message_price: response['messages'].first['message-price'])
        else
          ExceptionNotifier.notify_exception(StandardError.new, data: { message: "From send_and_save_message, unable to send message", from: from, to: to, text: message, env: Rails.env, response: response })
          false
        end
      end
    rescue Exception => err
      ExceptionNotifier.notify_exception(err, data: { message: "From send_and_save_message, unable to send message", from: from, to: to, text: message, env: Rails.env })
      false
    end
  end

  def self.num_of_segments(msg)
    (msg.bytesize/140.to_f).ceil
  end

  def self.relay_tip1
    "Relay tips: We've improved your payment experience with Relay by replacing the $ sign with a + tag. You can now text +10 instead of $10 to make a payment to a local business or non-profit."
  end

  def self.relay_tip2
    'Relay tips: With the + tag, you can now place the amount anywhere in the message. Ex. "pizza & broccoli +8 yay!" instead of "$8 pizza & broccoli'
  end

  def self.api_send(msg=nil)
    begin
      msg = msg.present? ? msg : 'Trios number test'
      webhook_url: '<redacted_webhook_url>'
      body = { key: 'wdJobH3wLOafkjPn3Yn5TQtt', secret: 'XyQjmW19Jf3cCNyesqEHmQtt', to: '<redacted_phone_number>',<redacted_phone_number>", body: msg }
      options = { body: body.to_json, headers: { 'Content-Type' => 'application/json' } }
      HTTParty.post(webhook_url, options)
    rescue StandardError => exception
      ExceptionNotifier.notify_exception(exception, data: { message: "In post_message_for_api_user", env: Rails.env, options: options })
    end
  end

  def self.api_send_local
    begin
      webhook_url: '<redacted_webhook_url>'
      body = { key: 'QBy6xmWxUkvCndzJmw1LcAtt', secret: '80O4jUQVdYSP3zrnPyYMMgtt', to: '<redacted_phone_number>',<redacted_phone_number>", body: "Api send test" }
      options = { body: body.to_json, headers: { 'Content-Type' => 'application/json' } }
      HTTParty.post(webhook_url, options)
    rescue StandardError => exception
      ExceptionNotifier.notify_exception(exception, data: { message: "In post_message_for_api_user local", options: options })
    end
  end

  def x(id_ary = [])
    user_ids = id_ary.present? ? id_ary : [7732, 7889, 7890, 7891, 7892, 7893]

    user_ids.each do |u_id|

      csv_string = CSV.generate do |csv|
        csv << ['Phone Number', 'Response', 'Segment', 'Timestamp (ET)', 'ID']
        #count = 0
        List.where(user_id: u_id, segment: nil).each do |l|
          UserList.where(list_id: l.id, customer_contact_type: 'MerchantContact').each do |ul|
            mc = MerchantContact.find_by(id: ul.customer_contact_id, is_customer: 0)
            if mc
              messages = Message.where(from: mc.uid, user_id_to: u_id)
              messages.each do |m|
                csv << [m.from, m.text, l.name, m.created_at.strftime("%Y-%m-%d %H:%M:%S"), m.id]
                #count = count + 1
                #puts count
              end
            end
          end
        end
      end

      attachment_hash = { attachments: [ { content: Base64.encode64(csv_string),
                                            name: "file.csv",
                                            type: "text/csv" } ] }

      EmailingService.email_to_platform("See Attached for User ID #{u_id}", 'RMG Data', attachment_hash)
    end
  end

#=begin
  def y
    ary = [
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>
    ]

    # nexmo
    ary.each_with_index { |n, i| TextingService.release_number_nexmo(n, "US"); puts i; }
    # ary.each_with_index { |n, i| TextingService.release_number_nexmo(n[0], n[1]); puts i; }
    # Twilio
    # ary.each_with_index { |n, i| TextingService.release_number(n); puts i; }
  end

  def yo
    Number.where(user_id: [39083, 39084, 39085]).each_with_index { |n, i| TextingService.release_number_nexmo(n.number, "CA"); puts i; }
  end

  def q
    ary = [
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>
    ]

    # nexmo
    #ary.each_with_index { |n, i| TextingService.release_number_nexmo(n, "US"); puts i; }
    # ary.each_with_index { |n, i| TextingService.release_number_nexmo(n[0], n[1]); puts i; }
    # Twilio
    ary.each_with_index { |n, i| TextingService.release_number(n); puts i; }
  end

  def z
    emails = %w(<redacted_email>)

    emails.each do |e|
      u = User.find_by(email: e.downcase)
      if u
        Number.where(user_id: u.id, provider: 'nexmo').pluck(:number).each_with_index { |n, i| TextingService.update_nexmo_number('CA', n, 'tel', <redacted_phone_number>); puts i; }
      end
    end

    #ary.each_with_index { |n, i| TextingService.update_nexmo_number('CA', n, 'tel', <redacted_phone_number>); puts i; }
    # ary.each_with_index { |n, i| TextingService.update_nexmo_number("CA", n, 'tel', "<redacted_phone_number>"); puts i; }
  end

  def p
    ary = [
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>
    ]

    user = User.find_by(id: 47945)
    ary.each_with_index do |n, i|
      n = n.to_s
      default = i == 0 ? 1 : 0
      #default = 0
      fn = '(' + n[1..3] + ') ' + n[4..6] + '-' + n[7..10]
      user.numbers.create(user_id: user.id, number: n, friendly_name: fn, country: 'CA', default: default, provider: 'nexmo', price: '210')
    end
  end
#=end


  def qwe
    # my numbers
    a = [
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>

    ]

    # twilio
    b = [
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>    ]

    c = []

    a.each { |e| puts "#{e}," if b.exclude? e }
    #b.find_all { |e| puts e if b.count(e) > 1 }
    nil
  end
end


