class FacebookMessengerService

  class << self
    
   
    def send_message   
      #Using HTTParty
      options = { body: {
        "recipient" => {
          "id" => "<redacted_phone_number>"
        },
        "message" => {
          "text" => "hello, world!"
        }
      }.to_json,
      headers: { 'Content-Type' => 'application/json' }}
      url = "https://graph.facebook.com/v2.6/me/messages?access_token=<redacted_facebook_access_token>"
      HTTParty.post(url, options)
    end

  end



end
