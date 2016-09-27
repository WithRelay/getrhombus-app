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

    def get_page(access_token)
      begin
        response = Koala::Facebook::API.new(access_token)
        page_array = response.get_object('me/accounts/page')
        page_array
      rescue Koala::Facebook::APIError => err
        nil
      end
    end

    def subscribe(page_access_token)
      begin
        subscribe_page = Koala::Facebook::API.new page_access_token
        response = subscribe_page.put_connections("me","subscribed_apps")
        response
      rescue Koala::Facebook::APIError => err
        nil
      end
    end

    def unsubscribe(page_access_token)
      begin
        subscribe_page = Koala::Facebook::API.new page_access_token
        response = subscribe_page.delete_connections("me","subscribed_apps")
        response
      rescue Koala::Facebook::APIError => err
        nil
      end
    end
  end
end
