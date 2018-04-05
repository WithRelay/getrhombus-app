class EveryoneApiService

  class << self

    def line_type(phone_number)
      begin
        account_sid = Rails.application.secrets.everyoneapi['account_sid']
        auth_token = Rails.application.secrets.everyoneapi['auth_token']

        url = "https://api.everyoneapi.com/v1/phone/#{phone_number}"\
              "?account_sid=#{account_sid}&auth_token=#{auth_token}"\
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
  end

end
