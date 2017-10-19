class WelcomeEmailJob < ApplicationJob
  queue_as :welcome_email

  def perform(user, customer_source)
    begin
      Resque.logger.debug 'job being settledddddddddddddddddddddd'
      Resque.logger.debug customer_source.inspect
      Resque.logger.debug 'job'
      puts 'dasdasdsassssssssssssssssssssssssss'

      if user.is_merchant?
        Rails.logger.debug 'im here'
        merchant, customer = user, nil
        EmailingService.welcome_email(user)
      elsif user.is_customer?
        if customer_source.present?
          Rails.logger.debug 'im hereeeeeeeeeeeeeee'
          sender = User.find_by(id: customer_source["id"])

          if customer_source["method"] == 'added'
            Rails.logger.debug 'im 2222222222222222222e'
            insert = (sender.first_name ? ", this is #{sender.first_name}" : '')
            text = "Hi#{insert} from #{sender.org_name}. You can now reach us on this number. If you have any questions or " + 
                    "will like to place an order, simply text us here."
            EmailingService.customer_added_to_relay(user, sender, customer_source['temp_password'])
          elsif customer_source["method"] == 'referred'
            text = "Thanks for signing up! Please add a payment card to your Relay profile (if you haven't done so). " +
                    "You can chat with us anytime via sms or to make a payment, just text the amount & description/hashtag. Ex. +10 #donut"
            EmailingService.customer_sign_up_from_referral_link(user, sender)
          end
        else
          sender = User.get_platform_acct_obj
          text = "Thanks for signing up! Please add a payment card to your Relay profile (if you haven't done so). You can chat with a " +
                  "local business anytime by texting their Relay number or to make a payment, just text the amount & description/hashtag. Ex. +10 #donut"
          EmailingService.customer_sign_up(user)
        end

        Conversation.find_or_create_conversation_for_message_and_send_publish(sender, user, 'user', user.id, text)
        merchant, customer = sender, user
      end
    rescue StandardError => exception
      ExceptionNotifier.notify_exception(exception, data: { message: "From WelcomeEmailJob", env: Rails.env, 
                                                            merchant: merchant, customer: customer })
    end
  end

end
