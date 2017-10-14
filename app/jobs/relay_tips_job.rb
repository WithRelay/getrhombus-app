class RelayTipsJob < ApplicationJob
  queue_as = :send_relay_tips

  def perform(customer, team)
    begin
      Conversation.find_or_create_conversation_for_message_and_send_publish(team, customer, 'user', customer.id, Message.relay_tip1)
      Conversation.find_or_create_conversation_for_message_and_send_publish(team, customer, 'user', customer.id, Message.relay_tip2)
    rescue StandardError => e
    end
  end

end
