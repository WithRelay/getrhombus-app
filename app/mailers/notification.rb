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

  def send_receipt(message, transaction_number, amount_with_taxes, amount, user_email, merchant_business_name, merchant_phone_number, merchant_email)
    @message = message
    @transaction_number = transaction_number
    @amount_with_taxes = amount_with_taxes
    @amount = amount
    @merchant_business_name = merchant_business_name
    @merchant_phone_number = merchant_phone_number
    @merchant_email = merchant_email
  	mail to: user_email, subject: "Payment Confirmation - #{transaction_number}"
  end

end
