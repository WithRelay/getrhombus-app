class Notification < ActionMailer::Base
  #default from: "<redacted_email>"
    default from: %("Rhombus" <<redacted_email>>)

  def welcome_email(email, user_level, name = "")
    @name = name
    @user_level = user_level
    mail to: email, subject: "Welcome to Rhombus Payments"
  end

  def payment_failure_notification(response, user, merchant, text, credit = "")
  	@response = response
    
    @user_email = user.email
    @user_phone_number = user.phone_number
    @text = text
    @card_name = user.card_name
    @last_four = user.last_four

    @merchant_email = merchant.email    
    @merchant_phone_number = merchant.business_phone
    @rhombus_number = merchant.rhombus_number

    @credit = credit
        
    if credit == ""
      subject = "Debit Charge Failure"
    else
      subject = "Credit Payment Failure"
    end

  	mail to: "<redacted_email>", subject: subject
  end


  def token_failure_notification(response, user_email)
    @response = response
    @email = user_email
    mail to: "<redacted_email>", subject: "Failed to Tokenize"
  end

  def text_failure_notification(response, from = "", to = "", message = "")
  	@response = response
    @from = from
    @to = to
    @text = message
  	mail to: "<redacted_email>", subject: "Nexmo API Error"
  end

  def send_receipt(message, transaction_number, amount_with_taxes, amount, user_email, merchant_business_name, merchant_phone_number, merchant_email)
    @message = message
    @transaction_number = transaction_number
    @amount_with_taxes = amount_with_taxes
    @amount = amount
    @merchant_business_name = merchant_business_name
    @merchant_phone_number = merchant_phone_number
    @merchant_email = merchant_email
  	mail to: user_email, subject: "Payment Confirmation - #{merchant_business_name}"
  end

  def send_merchant_receipt(debit_data, merchant, user, message, amount_less_fees)

    @message = message
    @transaction_number = debit_data[4]
    @transaction_uri = debit_data[5]
    @amount_with_taxes = debit_data[2]
    @amount_less_fees = amount_less_fees

    @user_email = user.email
    @user_phone_number = user.phone_number
    @card_name = user.card_name
    @last_four = user.last_four    
    @card_type = user.card_type

    @merchant_rhombus_number = merchant.rhombus_number
    mail to: merchant.email, subject: "#{user.card_name} sent you a payment via Rhombus"

  end

end
