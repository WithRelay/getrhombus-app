require 'uri'

class TextingService

  NEXMO_API_KEY = Rails.application.secrets.nexmo["key"]
  NEXMO_API_SECRET = Rails.application.secrets.nexmo["secret"]

  TWILIO_API_KEY = Rails.application.secrets.twilio["key"]
  TWILIO_API_SECRET = Rails.application.secrets.twilio["secret"]
  TWILIO_API_PHONE = Rails.application.secrets.twilio["phone"]
  TWILIO_RHOMBUS_APP_SID = Rails.application.secrets.twilio["rhombus_app_sid"]

  class << self

    def send_sms(from, to, client_ref, message)
      begin
        # encode the nexmo uri
        uri = URI.encode_www_form([["api_key",NEXMO_API_KEY], ["api_secret", NEXMO_API_SECRET], ["from", from], ["to", to], 
                        ["text", message], ["status-report-req", "1"], ["client-ref", client_ref]])   
        response = HTTParty.post('https://rest.nexmo.com/sms/json?'+ uri, :headers => {"Content-Type" => "application/x-www-form-urlencoded"} )
        return response
      rescue StandardError => err
        return false
      end
    end
  
     # we dont need client_ref here cos we have to use webhooks to listen to delivery??
    def send_sms_twilio(from, to, body, media_url = nil)
      begin
        client = Twilio::REST::Client.new TWILIO_API_KEY, TWILIO_API_SECRET
        data = { :from => from, :to => to, :body => body } 
        data[:media_url] = media_url if media_url  # US and canadian phone numbers can make use of an image as well.
        message = client.account.messages.create(data)
      rescue StandardError => err
        return false
      end
    end

    def receive_call
      response = Twilio::TwiML::Response.new do |r|
        # Should be your Twilio Number or a verified Caller ID
        r.Dial :callerId => '+<redacted_phone_number>' do |d|
            d.Client 'rho-jenny'
        end
      end
      return response
    end

    def get_twilio_capibility_token
      # This application sid will play a Welcome Message.
      demo_app_sid = '<redacted_twilio_app_sid>'
      capability = Twilio::Util::Capability.new TWILIO_API_KEY, TWILIO_API_SECRET
      capability.allow_client_outgoing '<redacted_twilio_app_sid>'
      capability.allow_client_incoming "rho-jenny"
      token = capability.generate
      return token
    end

    def buy_number(num)
      begin  
        client = Twilio::REST::Client.new TWILIO_API_KEY, TWILIO_API_SECRET
        number = client.account.incoming_phone_numbers.create(:phone_number => num, :VoiceApplicationSid => TWILIO_RHOMBUS_APP_SID,
         :SmsApplicationSid => TWILIO_RHOMBUS_APP_SID)        
      rescue StandardError => e
        return false
      else
        return true
      end
    end

    def search_number(str, type, country)
      client = Twilio::REST::Client.new TWILIO_API_KEY, TWILIO_API_SECRET
      begin  
        search_params = {}
        search_params[type] = str

        local_numbers = client.account.available_phone_numbers.get('US').local.list(search_params)
        return local_numbers[0].phone_number unless local_numbers.empty?
        return []
      rescue StandardError => e
          return e.message #[]
      end
    end
    
  end

end

