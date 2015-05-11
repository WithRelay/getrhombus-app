class Notification < ActionMailer::Base
  
  TEAM_EMAIL = Rails.application.secrets.team_email
  default from: TEAM_EMAIL
  

  def token_failure_notification(response, user_email)
    @response = response
    @email = user_email
    mail to: TEAM_EMAIL, subject: "Failed to Tokenize"
  end

  def text_failure_notification(response, from = "", to = "", message = "")
  	@response = response
    @from = from
    @to = to
    @text = message
  	mail to: TEAM_EMAIL, subject: "Nexmo API Error"
  end
end
