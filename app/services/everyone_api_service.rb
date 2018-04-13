class EveryoneApiService

  ACCOUNT_SID = Rails.application.secrets.everyoneapi['account_sid']
  AUTH_TOKEN = Rails.application.secrets.everyoneapi['auth_token']

  class << self

    def line_type(phone_number)
      begin
        url = "https://api.everyoneapi.com/v1/phone/#{phone_number}"\
              "?account_sid=#{ACCOUNT_SID}&auth_token=#{AUTH_TOKEN}"\
              "&data=linetype"
        
        res = HTTParty.get(url)
        res.success? ? res.parsed_response["data"]["linetype"] : false
      rescue Exception => error
        ExceptionNotifier.notify_exception(
          error,
          data: {
            message: 'In EveryoneApi verify_phone',
            env: Rails.env
          }
        )
        false
      end
    end

     def enrich_number(phone_number)
      begin
        url = "https://api.everyoneapi.com/v1/phone/#{phone_number}"\
              "?account_sid=#{ACCOUNT_SID}&auth_token=#{AUTH_TOKEN}"\
              "&data=name,address,cnam,carrier,gender,linetype,line_provider,profile"
        
        res = HTTParty.get(url)
        res.success? ? res.parsed_response : false
      rescue Exception => error
        ExceptionNotifier.notify_exception(
          error,
          data: {
            message: 'In EveryoneApi enrich_number',
            env: Rails.env
          }
        )
        false
      end
    end


  end

end
