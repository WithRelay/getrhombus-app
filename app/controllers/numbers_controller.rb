# frozen_string_literal: true

class NumbersController < ApplicationController
  def new; end

  def create
    re = current_user.buy_number(params['number'])
    if re
      msg_to_send = "Hi, this is Taiwo. Info is #{current_user.email}, #{current_user.card_name}, #{current_user.org_name}. To disable the account, cancel subscription in Stripe but also notify me so I can close the account."
      @merchant = User.find(1)
      %w[].each do |num|
        @customer = User.find_by(phone_number: num)
        Conversation.find_or_create_conversation_for_message_and_send_publish(@merchant, @customer, 'user',
                                                                              @customer.id, msg_to_send)
      end
      EmailingService.notify_admins(msg_to_send)

      flash[:notice] = 'Relay number added'
      redirect_to user_conversations_path
    else
      flash[:error] = 'We are unable to assign a Relay number. A member of our support team will contact you shortly.'
      ExceptionNotifier.notify_exception(StandardError.new, env: request.env, data: { message: "Unable to assign number for id #{current_user.id}",
                                                                                      env: Rails.env, re: re })
      redirect_to user_add_rhombus_number_path
    end
  end
end
