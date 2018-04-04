# Phone number validator with everyoneapi
class PhoneNumberValidatorService
  include HTTParty
  attr_reader :phone_number
  def initialize(phone_number)
    @phone_number = phone_number
  end

  def verify_phone
    begin
      account_sid = Rails.application.secrets.everyoneapi['account_sid']
      auth_token = Rails.application.secrets.everyoneapi['auth_token']
      url = "https://api.everyoneapi.com/v1/phone/#{phone_number}"\
            "?account_sid=#{account_sid}&auth_token=#{auth_token}"\
            '&data=name,address,location,cnam,carrier,carrier_o'\
            ',gender,linetype,image,line_provider,profile'
      res = self.class.get(url)
      res.success? ? res.parsed_response : false
    rescue StandardError => error
      ExceptionNotifier.notify_exception(
        error,
        data: {
          message: 'In PhoneNumber Validator Service',
          env: Rails.env
        }
      )
      false
    end
  end
end
