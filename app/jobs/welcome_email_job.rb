class WelcomeEmailJob < ApplicationJob
  queue_as :welcome_email

  def perform(user)
    begin
      if user.is_merchant? && !user.is_platform?
        EmailingService.welcome_email(user)
      elsif user.is_customer?
        if user.customer_source.present?
          sender = User.find_by(id: user.customer_source.id)

          if user.customer_source.method == 'added'
            insert = (sender.first_name ? ", it's #{sender.first_name}" : '')
            text = "Hi#{insert} from #{sender.org_name}. You can now reach us on this number. If you have any questions or \
            will like to place an order, simply text us here."
            EmailingService.customer_added_to_relay(user, sender)
          elsif user.customer_source.method == 'referred'
            text = "Thanks for signing up! Please add a payment card to your Relay profile (if you haven't done so). \
            You can chat with us anytime via sms or to make a payment, just text the amount & description/hashtag. Ex. +10 #donut"
            EmailingService.customer_sign_up_from_referral_link(user, sender)
          end
        else
          sender = User.get_platform_acct_obj
          text = "Thanks for signing up! Please add a payment card to your Relay profile (if you haven't done so). \
          You can chat with a local business anytime by texting their Relay number or to make a payment, just text the amount & \
          description/hashtag. Ex. +10 #donut"
          EmailingService.customer_sign_up(user)
        end

        Conversation.find_or_create_conversation_for_message_and_send_publish(sender, user, 'user', user.id, text, 'Message')
      end
      rescue StandardError => e
        # send us error message
      end
    end

end
