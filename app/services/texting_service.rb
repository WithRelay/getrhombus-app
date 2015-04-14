class TextingService

  require 'uri'

  def send_sms(from, to, message)
    # change to test keys and move to secrets.rb
    api_key: '<redacted_api_key>' #8e2e5cab
    api_secret: '<redacted_api_secret>'
    # encode the nexmo uri
    uri = URI.encode_www_form([["api_key",api_key], ["api_secret", api_secret], ["from", from], ["to", to], 
                    ["text", message], ["status-report-req", "1"], ["client-ref", client_ref]])   
    # call nexmo api
    response = HTTParty.post('https://rest.nexmo.com/sms/json?'+ uri, :headers => {"Content-Type" => "application/x-www-form-urlencoded"} )
    return response
  end

  def buy_number(country)
    # change to test keys and move to secrets.rb
    api_key: '<redacted_api_key>' #8e2e5cab
    api_secret: '<redacted_api_secret>'
    
    # search for a number on nexmo
    response = HTTParty.get('https://rest.nexmo.com/number/search/'+ api_key + "/" + api_secret + "/" + country + "?features=SMS,VOICE&size=1")
    # check the response
    if response.code == 200 and response["numbers"] != nil #.first["msisdn"] != ""
      msisdn = response["numbers"].first["msisdn"]
      response = HTTParty.post('https://rest.nexmo.com/number/buy/'+ api_key + "/" + api_secret + "/" + country + "/" + msisdn)
      
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

