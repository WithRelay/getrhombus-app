require 'uri'

class TextingService

  NEXMO_API_KEY = Rails.application.secrets.nexmo["key"]
  NEXMO_API_SECRET = Rails.application.secrets.nexmo["secret"]

  class << self

    def send_sms(from, to, client_ref, message)
      # encode the nexmo uri
      uri = URI.encode_www_form([["api_key",NEXMO_API_KEY], ["api_secret", NEXMO_API_SECRET], ["from", from], ["to", to], 
                      ["text", message], ["status-report-req", "1"], ["client-ref", client_ref]])   
      # call nexmo api
      response = HTTParty.post('https://rest.nexmo.com/sms/json?'+ uri, :headers => {"Content-Type" => "application/x-www-form-urlencoded"} )
      return response
    end
  
    def buy_number(country)
      # search for a number on nexmo
      response = HTTParty.get('https://rest.nexmo.com/number/search/'+ NEXMO_API_KEY + "/" + NEXMO_API_SECRET + "/" + country + "?features=SMS,VOICE&size=1")
      # check the response
      if response.code == 200 and response["numbers"] != nil #.first["msisdn"] != ""
        msisdn = response["numbers"].first["msisdn"]
        response = HTTParty.post('https://rest.nexmo.com/number/buy/'+ NEXMO_API_KEY + "/" + NEXMO_API_SECRET + "/" + country + "/" + msisdn)
        
        # check response
        if response.code == 200
          return msisdn
        else
          # Notify marketplace owner of failure
          Notification.text_failure_notification(response, from = "", to = "", message = "Rhombus number purchase failed with response code #{response.code}").deliver_now
          return "-"
        end
      else
        # Notify marketplace owner of failure
        Notification.text_failure_notification(response, from = "", to = "", message = "Rhombus number search failed").deliver_now
        return "-"
      end
    end
    
  end

end

