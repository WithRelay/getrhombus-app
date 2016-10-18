class FacebookMessengerService

  class << self

    # for messenger_account_linking 
    def send_auth_link(page_access_token, recipient_id, welcome_text)
      body = {
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
      }
      httparty_post(body, page_access_token) 
    end

    # update new user from messenger's email from account linking
    def update_user_fb_cred(params)
      account_linking_token = params['account_linking_token']
      subscribed_page = FbPage.where(subscription_status: true)
      token_array = subscribed_page.pluck('page_access_token')
      token_array.each do |token|
        response = JSON.parse get_page_scope_id(account_linking_token, token)
        if response
          psid = response['recipient']
          fb_user = FbCred.find_by_page_specific_id psid
          fb_user.update(email: params['email'])
          break
        end
      end
    end

    def get_page_scope_id(account_linking_token, page_access_token)
      url = "https://graph.facebook.com/v2.6/me?access_token=#{page_access_token}\
            &fields=recipient\
            &account_linking_token=#{account_linking_token}"
      HTTParty.get(url)
    end

    def send_text_message(page_access_token, recipient_id, text)  
      #Using HTTParty
      # page_access_token = "<redacted_facebook_access_token>"
      # recipient_id = "<redacted_phone_number>"
      # text = "welcome!!"
      body = {
        "recipient" => {
          "id" => recipient_id
        },
        "message" => {
          "text" => text
        }
      }
      httparty_post(body, page_access_token)
    end

    def send_attachment(page_access_token, recipient_id, attachment_type, file_url) 
      # page_access_token = "<redacted_facebook_access_token>"
      # recipient_id = "<redacted_phone_number>"
      # attachment_type = "image"
      # file_url = "http://v.img.com.ua/b/orig/b/b1/b91937118c0414fda58d5f020b518b1b.jpg" 
      body = {
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
      }
      httparty_post(body, page_access_token)
    end

    def httparty_post(post_body, access_token)
      begin
        options = { body: post_body.to_json,
          headers: { 'Content-Type' => 'application/json' }}
        url = "https://graph.facebook.com/v2.7/me/messages?access_token=#{access_token}"
        HTTParty.post(url, options)
      rescue HTTParty::Error => err
        nil
      end
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
      begin
        graph = Koala::Facebook::API.new(access_token)
        graph.get_picture(id, type: :large)
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
