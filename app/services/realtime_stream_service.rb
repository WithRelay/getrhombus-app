class RealtimeStreamService

  class << self
    
    # Sends a message to the given merchant's channel, provided user and merchant numbers
    def send_message_via_number(user_number, merchant_number, message, message_ts, is_merchant_message = false)
      user = User.find_by_phone_number(user_number)
      merchant = User.find_by_rhombus_number(merchant_number)
      
      if !user.blank? && !merchant.blank?
        send_message_via_id(user.id, merchant.id, message, message_ts, is_merchant_message)
      end
    end

    # Sends a message to the given merchant's channel, provided user and merchant ids
    def send_message_via_id(user_id, merchant_id, message, message_ts, is_merchant_message = false)
      $pubnub.subscribe(
        :channel  => 'messaging_' + Rails.env + '_' + merchant_id.to_s
      ) {}
      
      user = User.find_by_id(user_id)
      user_level = is_merchant_message ? 1 : user.user_level
      
      $pubnub.publish(
        :channel  => 'messaging_' + Rails.env + '_' + merchant_id.to_s,
        :message => Hash[
          'user_id' => user_id,
          'first_name' => user.first_name,
          'last_name' => user.last_name,
          'email' => user.email,
          'user_level' => user_level,
          'image_url' => user_level == 0 ? ActionController::Base.helpers.asset_path('user_icon_50x50.png') : ActionController::Base.helpers.asset_path('rhombus_icon_50x50.png'),
          'message' => message,
          'ts_day_of_the_week' => message_ts.strftime('%A'),
          'ts_time' => message_ts.strftime('%l:%M %P'),
          'ts_int' => message_ts.to_i,
          'unread' => false
        ].to_json
      ) {}
    end

    def send_message_via_number1(user_number, merchant_number, message, message_ts, is_merchant_message = false)
      merchant = User.find_by_rhombus_number(merchant_number)
      if !merchant.blank?
        send_message_via_id(user_number, merchant.id, message, message_ts, is_merchant_message)
      end
    end
    
    # Sends a message to the given merchant's channel, provided user and merchant ids
    def send_message_via_id1(user_number, merchant_id, message, message_ts, is_merchant_message = false)
      $pubnub.subscribe(
        :channel  => 'messaging_' + Rails.env + '_' + merchant_id.to_s
      ) {}
      
      user = User.where(phone_number: user_number)
      user_level = (user.blank?) ? 0 : user.user_level
      user_level = is_merchant_message ? 1 : user_level
      
      $pubnub.publish(
        :channel  => 'messaging_' + Rails.env + '_' + merchant_id.to_s,
        :message => Hash[
          'user_id' => user_number,
          'first_name' => (user.blank? && user.first_name.blank?) ? user_number : user.first_name,
          'last_name' => (user.blank? && user.last_name.blank?) ? "" : user.last_name,
          'email' => (user.blank? && user.email.blank?) ? "user isn't signed up :(" : user.email,
          'user_level' => user_level,
          'image_url' => user_level == 0 ? ActionController::Base.helpers.asset_path('user_icon_50x50.png') : ActionController::Base.helpers.asset_path('rhombus_icon_50x50.png'),
          'message' => message,
          'ts_day_of_the_week' => message_ts.strftime('%A'),
          'ts_time' => message_ts.strftime('%l:%M %P'),
          'ts_int' => message_ts.to_i,
          'unread' => false
        ].to_json
      ) {}
    end
    
  end
  
end

