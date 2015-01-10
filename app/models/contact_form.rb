class ContactForm < MailForm::Base
  append :remote_ip, :user_agent#, :session#  => TMI

  attribute :name,      :validate => true #:presence_of
  attribute :email,     :validate => /\A([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})\z/i
  attribute :organization
  attribute :message,   :validate => true
  attribute :nickname,  :captcha  => true

  # Declare the e-mail headers. It accepts anything the mail method
  # in ActionMailer accepts.
 def headers
    {
      :subject => "Contact Us",
      :to => "<redacted_email>",
      :from => "#{name} <#{email}>"
    }
  end

=begin
  def presence_of
    if name.blank?
      self.errors.add(:name, "Please enter your full name.")
    end
  end
=end

end