class Notification < ActionMailer::Base
  default from: "<redacted_email>"

  def payment_failure_notification(response, merchant_email = '')
  	@response = response
  	mail to: "<redacted_email>", subject: "Error message test"
  end

  def token_failure_notification(response, user_email)
    @response = response
    mail to: "<redacted_email>", subject: "Error message test"
  end

  def text_failure_notification(response)
  	@response = response
  	mail to: "<redacted_email>", subject: "Error message test"
  end

  def send_receipt(response, tax_rate, merchant_business_name)
  	mail to: "<redacted_email>", subject: "Payment, tax rate #{tax_rate}, merchant biz name: #{merchant_business_name}"
  end

end
