class EmailValidatorService

  class << self

    def verify_email(email)
      begin
        secret = Rails.application.secrets.emaillistverify["secret"]
        res = HTTParty.get( "https://apps.emaillistverify.com/api/verifyEmail?secret=#{secret}&email=#{email}" )
        return true if res.code == 200 && res.parsed_response != "fail"
      rescue StandardError => e
      end
      false
    end
  end
end
