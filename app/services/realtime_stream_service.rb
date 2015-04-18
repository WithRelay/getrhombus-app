class RealtimeStreamService

  class << self
    
    # Sends a message to the given merchant's channel
    def send_message(user_id, merchant_id, message)
      $pubnub.subscribe(
        :channel  => 'messaging_' + merchant_id.to_s
      ) {}
      
      $pubnub.publish(
        :channel  => 'messaging_' + merchant_id.to_s,
        :message => message
      ) {}
    end
    
  end
  
end

