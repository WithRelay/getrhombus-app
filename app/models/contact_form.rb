class ContactForm < MailForm::Base
  append :remote_ip, :user_agent#, :session#  => TMI

  attribute :name,      :validate => true
  attribute :email,     :validate => /\A([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})\z/i
  attribute :organization
  attribute :message,   :validate => true
  attribute :nickname,  :captcha  => true

  # Declare the e-mail headers. It accepts anything the mail method
  # in ActionMailer accepts.
 def headers
    {
      :subject => "#{name} just contacted us",
      :to => Rails.application.secrets.team_email,
      :from => Rails.application.secrets.team_email,
      :reply_to => "#{name} <#{email}>"
    }
  end

end