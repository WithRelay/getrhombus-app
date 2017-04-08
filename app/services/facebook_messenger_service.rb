class FacebookMessengerService

  class << self

    # for messenger_account_linking
    def send_auth_link(page_access_token, recipient_id, welcome_text)
      link_url = (Rails.env == 'production')? "https://www.getrhombus.com/link_facebook" : "https://5c547308.ngrok.io/link_facebook"
      body = {
        recipient:{
          id: recipient_id
        },
        message: {
          attachment: {
            type: "template",
            payload: {
              template_type: "generic",
              elements: [{
                title: welcome_text,
                image_url: "https://www.getrhombus.com/assets/imgo-252069578bf9441f8f0cf59bc8660170.jpg",
                buttons: [{
                  type: "account_link",
                  url: link_url
                }]
              }]
            }
          }
        }
      }
      httparty_post(body, page_access_token)
    end

    # update new user from messenger's email from account linking
    def update_user_fb_cred(referee, params)
      account_linking_token = params['account_linking_token']
      response = get_page_response account_linking_token
      if response
        response = JSON.parse response
        psid = response['recipient']
        fb_cred = FbCred.find_by(page_specific_id: psid)
        fb_cred.update(email: params['email'], user_id: referee.id) if fb_cred
      end
    end

    def get_page_response(account_linking_token)
      subscribed_pages = FbPage.subscribed
      subscribed_pages.each do | subscribed_page|
        token = subscribed_page[:page_access_token]
        response = get_page_scope_id(account_linking_token, token)
        if response['recipient'].present?
          return response
        end
      end
    end

    def get_page_scope_id(account_linking_token, page_access_token)
      begin
        url = "https://graph.facebook.com/v2.6/me?access_token=#{page_access_token}\
              &fields=recipient\
              &account_linking_token=#{account_linking_token}"
        HTTParty.get(url)
      # Exception: HTTParty::Error Inherits:StandardError
      rescue StandardError => err
        nil
      end
    end

    def send_text_message(page_access_token, recipient_id, text)
      body = {
        recipient: {
          id: recipient_id
        },
        message: {
          text: text
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
        recipient:{
          id: recipient_id
        },
        message:{
          attachment:{
            type: attachment_type,
            payload:{
              url: file_url
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
      rescue StandardError => err
      end
    end

    def get_user_info(page_token, user_id)
      begin
        page_graph = Koala::Facebook::API.new(page_token)
        page_graph.get_object(user_id)
      # Exception: Koala::KoalaError Inherits:StandardError
      rescue StandardError => err; end
    end

    def get_page(access_token)
      begin
        response = Koala::Facebook::API.new(access_token)
        page_array = response.get_object('me/accounts/page')
        page_array
      rescue StandardError => err
      end
    end

    # it gives 200*200 profile pic of facebook user
    def get_profile_pic(access_token, id)
      begin
        graph = Koala::Facebook::API.new(access_token)
        graph.get_picture(id, type: :large)
      rescue StandardError => err
      end
    end

    def subscribe(page_access_token)
      begin
        subscribe_page = Koala::Facebook::API.new page_access_token
        response = subscribe_page.put_connections("me","subscribed_apps")
        response
      rescue StandardError => err
      end
    end

    def unsubscribe(page_access_token)
      begin
        subscribe_page = Koala::Facebook::API.new page_access_token
        response = subscribe_page.delete_connections("me","subscribed_apps")
        response
      rescue StandardError => err
      end
    end

  end

end
