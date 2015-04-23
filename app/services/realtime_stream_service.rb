class RealtimeStreamService

  class << self
    
    # Sends a message to the given merchant's channel
    def send_message(user_id, merchant_id, message, message_ts)
      $pubnub.subscribe(
        :channel  => 'messaging_' + merchant_id.to_s
      ) {}
      
      user = User.find_by_id(user_id)
      
      $pubnub.publish(
        :channel  => 'messaging_' + merchant_id.to_s,
        :message => Hash[
          'user_id' => user_id,
          'first_name' => user.first_name,
          'last_name' => user.last_name,
          'email' => user.email,
          'user_level' => user.user_level,
          'image_url' => user.user_level == 0 ? ActionController::Base.helpers.asset_path('user_icon_50x50.png') : ActionController::Base.helpers.asset_path('rhombus_icon_50x50.png'),
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

