class RulesEngineJob < ApplicationJob
  queue_as :rules

  def perform(message_id)
    @message = Message.includes(:user).find_by(id: message_id)
    run_rules
  end

  def run_rules
    begin
      message_text = @message.text.downcase.strip
      return if message_text.blank?

      @merchant = User.find_by(id: @message.user_id_to)
      rules = @merchant.rules      
      return if rules.blank?

      rules.each do |rule|
        rule_text = rule.text.downcase.strip
        response = rule.response

        case rule.rule_type
        when 'starts_with_text'
          if message_text.starts_with?(rule_text)
            send_response(response)
            break
          end
        when 'starts_with_text_and_length_is_less_than_x'
          if message_text.starts_with?(rule_text) && message_text.size < rule.message_length
            send_response(response)
            break
          end
        when 'contains_text'
          if message_text.include?(rule_text)
            send_response(response)
            break
          end
        when 'contains_only_text'
          if message_text == rule_text
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
              message: 'From RulesEngineJob, rule mismatch',
              rule: rule.attributes,
              env: Rails.env
            }
          )
        end
      end

    rescue Exception => err
      ExceptionNotifier.notify_exception(
        StandardError.new,
        env: Rails.env,
        data: {
          message: 'From RulesEngineJob, something went wrong',
          message: @message,
          env: Rails.env
        }
      )
    end

  end

  def send_response(response_text)
    customer = @message.user
    uid, uid_type = customer.present? ? [customer.id, 'user'] : @message.from, 'phone_number'
    Conversation.find_or_create_conversation_for_message_and_send_publish(@merchant, customer, uid_type, uid, response_text, 'Message', [], 'platform', @message.to)
  end
end
