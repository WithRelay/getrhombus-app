class RulesEngineJob < ApplicationJob
  queue_as :rules

  def perform(message_id)
    @message = Message.find_by(id: message_id)
    @merchant = User.find_by(id: @message.user_id_to)
    run_rules
  end

  def run_rules
    message_text = @message.text.downcase
    rules = @merchant.try(:rules)
    return if rules.blank?
    rules.each do |rule|
      rule_text = rule.text.downcase
      response = rule.response
      case rule.rule_type
      when 'contains_text'
        if message_text.include?(rule_text)
          send_response(response)
          break
        end
      when 'contains_only_text'
        if message_text.casecmp(rule_text).zero?
          send_response(response)
          break
        end
      when 'contains_text_and_length_is_less_than_x'
        if message_text.include?(rule_text) && message_text.size < rule.message_length
          send_response(response)
          break
        end
      else
        ExceptionNotifier.notify_exception(
          StandardError.new,
          env: Rails.env,
          data: {
            message: 'From RulesEngineJob, rule missmatch',
            rule: rule.attributes,
            env: Rails.env
          }
        )
      end
    end
  end

  def send_response(response_text)
    conv = @message.conversations.last
    Conversation.send_message(conv, @merchant, response_text, 'Message', 'merchant', [], @message.to)
  end
end
