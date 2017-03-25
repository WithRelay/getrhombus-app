class WelcomeEmailJob < ApplicationJob
  queue_as :welcome_email

  def perform(user)
    begin
      owner = User.get_platform_acct_obj
      if user.is_merchant?
        EmailingService.send_welcome_email(user.email, owner.rhombus_number, "merchant")
      elsif user.is_customer?
        ref = user.referrers.first
        message = Message.new
        unless ref.blank?
          referrer = User.find_by(id: ref.referrer_id)
          EmailingService.send_welcome_email_with_referral(referrer.email, user.email, referrer.org_name, referrer.rhombus_number, owner.rhombus_number)
          text = "Thanks for signing up! Please add a payment card to your Rhombus profile (if you haven't done so).
          You can chat with us anytime via sms or to make a payment, just text the amount & description/hashtag. Ex. +10 #donut"
          message.send_and_save_message(referrer, user, referrer.rhombus_number, user.phone_number, text)
        else
          EmailingService.send_welcome_email(user.email, owner.rhombus_number, "customer")
          text = "Thanks for signing up! Please add a payment card to your Rhombus profile (if you haven't done so).
          You can chat with a local business anytime by texting their Rhombus number or to make a payment, just text the amount &
          description/hashtag. Ex. +10 #donut"
          message.send_and_save_message(owner, user, owner.rhombus_number, user.phone_number, text)
        end
      end
      rescue StandardError => e
      end
	  end

end
