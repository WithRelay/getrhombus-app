class Notification < ActionMailer::Base
  default from: "<redacted_email>"

  def failure_notification(response)
  	@response = response
  	mail to: "<redacted_email>", subject: "Error message test"
  end

  def send_receipt
  end

end
