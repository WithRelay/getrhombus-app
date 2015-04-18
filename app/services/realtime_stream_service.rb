class RealtimeStreamService

  class << self
    
    # Sends a message to the given merchant's channel
    def send_message(user_id, merchant_id, message)
      $pubnub.subscribe(
        :channel  => 'messaging_' + merchant_id.to_s
      ) {}
      
      user = User.find_by_id(user_id)
      
      $pubnub.publish(
        :channel  => 'messaging_' + merchant_id.to_s,
        :message => Hash[
          'user_id' => user_id,
          'user_level' => user.user_level,
          'image_url' => user.user_level == 0 ? ActionController::Base.helpers.asset_path('user_icon_50x50.png') : ActionController::Base.helpers.asset_path('rhombus_icon_50x50.png'),
          'text' => message,
          'unread' => false
        ].to_json
      ) {}
    end
    
  end
  
end

