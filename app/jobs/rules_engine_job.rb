# frozen_string_literal: true

class RulesEngineJob < ApplicationJob
  queue_as :rules

  EXCLUSIONS = %w[
    <redacted_phone_number>
    <redacted_phone_number>
    <redacted_phone_number>
    <redacted_phone_number>
    <redacted_phone_number>
    <redacted_phone_number>
    <redacted_phone_number>
    <redacted_phone_number>
    <redacted_phone_number>
    <redacted_phone_number>
    <redacted_phone_number>
    <redacted_phone_number>
    <redacted_phone_number>
  ].freeze

  def perform(message_id)
    @message = Message.includes(:user).find_by(id: message_id)
    run_rules if @message && EXCLUSIONS.exclude?(@message.from)
  end

  def run_rules
    message_text = @message.text.downcase.strip
    return if message_text.blank?

    @merchant = User.find_by(id: @message.user_id_to)
    rules = @merchant.rules.order(id: :asc).pluck(:text, :response, :rule_type, :message_length, :id)
    return if rules.blank?

    rules.each do |rule|
      rule_text = rule.first.downcase.strip
      response = rule.second

      case rule.third
      when 'starts_with_text'
        if message_text.starts_with?(rule_text)
          send_response(response)
          break
        end
      when 'starts_with_text_and_length_is_less_than_x'
        if message_text.starts_with?(rule_text) && message_text.size < (rule.fourth + 1)
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
        if message_text.include?(rule_text) && message_text.size < (rule.fourth + 1)
          send_response(response)
          break
        end
      else
        ExceptionNotifier.notify_exception(
          StandardError.new,
          env: Rails.env,
          data: {
            message: 'From RulesEngineJob, rule mismatch',
            rule: rule,
            env: Rails.env
          }
        )
      end
    end
  rescue Exception => e
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

  def send_response(response_text)
    # while rules soon after an inbound message. It might be better to search for user by phone number instead of id.
    customer = @message.user
    person = customer
    if customer.present?
      uid = customer.id
      uid_type = 'user'
    else
      uid = @message.from
      uid_type = 'phone_number'
      person = MerchantContact.find_by(merchant_id: @merchant.id, uid: uid, uid_type: uid_type)
    end
    if person.present? && @merchant.present?
      response_text = CampaignHandlebar.new(person, @merchant).render(response_text)
    end
    Conversation.find_or_create_conversation_for_message_and_send_publish(@merchant, customer, uid_type, uid, response_text, 'Message', [], 'platform', @message.to)
  end
end
