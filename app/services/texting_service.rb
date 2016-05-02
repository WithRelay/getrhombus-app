require 'uri'
  
  # help thorough implementation needed per doc above

class TextingService

  NEXMO_API_KEY = Rails.application.secrets.nexmo["key"]
  NEXMO_API_SECRET = Rails.application.secrets.nexmo["secret"]

  TWILIO_API_KEY = Rails.application.secrets.twilio["key"]
  TWILIO_API_SECRET = Rails.application.secrets.twilio["secret"]
  TWILIO_API_PHONE = Rails.application.secrets.twilio["phone"]
  TWILIO_RHOMBUS_APP_SID = Rails.application.secrets.twilio["rhombus_app_sid"]

  class << self

    def send_sms_nexmo(from, to, message)
      begin
        # encode the nexmo uri
        uri = URI.encode_www_form([["api_key",NEXMO_API_KEY], ["api_secret", NEXMO_API_SECRET], ["from", from], ["to", to], ["text", message]])   
        response = HTTParty.post('https://rest.nexmo.com/sms/json?'+ uri, :headers => {"Content-Type" => "application/x-www-form-urlencoded"} )
      rescue StandardError => err
        return err
      end
    end
  
    def send_sms(from, to, body, media_url = nil)
      begin
        client = Twilio::REST::Client.new TWILIO_API_KEY, TWILIO_API_SECRET
        data = { From: from, To: to, Body: body, ApplicationSid: TWILIO_RHOMBUS_APP_SID } 
        data[:media_url] = media_url if media_url  # US and canadian phone numbers can make use of an image as well.
        message = client.account.messages.create(data)
      rescue StandardError => err
        return err
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
        return true    
      rescue StandardError => e
        return false
      end
    end

    def search_number(str, type, country)
      # https://www.twilio.com/help/faq/phone-numbers/which-countries-does-twilio-have-phone-numbers-in-and-what-are-their-capabilities
      client = Twilio::REST::Client.new TWILIO_API_KEY, TWILIO_API_SECRET
      begin  
        search_params = { voice_enabled: "true", sms_enabled: "true", exclude_all_address_required: "true" }
        search_params[:mms_enabled] = "true" if ["US", "CA"].include? country
        search_params[type] = str

        local_numbers = client.account.available_phone_numbers.get(country).local.list(search_params)[0..4]
        return local_numbers.map { |p| p.phone_number } 
      rescue StandardError => e
          return e.message #[]
      end
    end
    
  end
end

