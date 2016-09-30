class FacebookMessengerService

  class << self

    def send_auth_link(page_access_token, recipient_id, welcome_text)
      options = { 
        body: {
          "recipient":{
            "id": recipient_id
          },
          "message": {
            "attachment": {
              "type": "template",
              "payload": {
                "template_type": "generic",
                "elements": [{
                  "title": welcome_text,
                  "image_url": "https://www.getrhombus.com/assets/imgo-252069578bf9441f8f0cf59bc8660170.jpg",
                  "buttons": [{
                    "type": "account_link",
                    "url": "<redacted_webhook_url>"
                  }]
                }]
              }
            }
          }
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      }
      url = "https://graph.facebook.com/v2.7/me/messages?access_token=#{page_access_token}"
      HTTParty.post(url, options)   
    end

    def send_text_message(page_access_token, recipient_id, text)  
      #Using HTTParty
      # page_access_token = "<redacted_facebook_access_token>"
      # recipient_id = "<redacted_phone_number>"
      # text = "welcome!!"
      options = { body: {
        "recipient" => {
          "id" => recipient_id
        },
        "message" => {
          "text" => text
        }
      }.to_json,
      headers: { 'Content-Type' => 'application/json' }}
      url = "https://graph.facebook.com/v2.7/me/messages?access_token=#{page_access_token}"
      HTTParty.post(url, options)
    end

    def send_attachment(page_access_token, recipient_id, attachment_type, file_url) 
      # page_access_token = "<redacted_facebook_access_token>"
      # recipient_id = "<redacted_phone_number>"
      # attachment_type = "image"
      # file_url = "http://v.img.com.ua/b/orig/b/b1/b91937118c0414fda58d5f020b518b1b.jpg" 
      options = { body: {
        "recipient":{
          "id": recipient_id
        },
        "message":{
          "attachment":{
            "type": attachment_type,
            "payload":{
              "url": file_url
            }
          }
        }
      }.to_json,
      headers: { 'Content-Type' => 'application/json' }}
      url = "https://graph.facebook.com/v2.7/me/messages?access_token=#{page_access_token}"
      HTTParty.post(url, options)
    end

    def get_user_info(page_token, user_id)
      begin
        page_graph = Koala::Facebook::API.new(page_token)
        page_graph.get_object(user_id)
      rescue Koala::Facebook::APIError => err
      end
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

    # it gives 200*200 profile pic of facebook user
    def get_profile_pic(access_token, id)
      graph = Koala::Facebook::API.new(access_token)
      graph.get_picture(id, type: :large)
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
