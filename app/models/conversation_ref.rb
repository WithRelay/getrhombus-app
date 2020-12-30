# frozen_string_literal: true

class ConversationRef < ActiveRecord::Base
  belongs_to :textable, polymorphic: true
  belongs_to :conversation
  has_one :merchant_conversation_resolution, class_name: 'ConversationResolution', foreign_key: 'merchant_conversation_ref_id'
  has_one :uid_conversation_resolution, class_name: 'ConversationResolution', foreign_key: 'uid_conversation_ref_id'

  enum source: { platform: 0, merchant: 1, customer: 2, campaign: 3 }

  # the last message in all conversations within a thread between a merchant and customer/contact
  def self.get_last_customer_msg_from_all_merchant_convs(merchant_id, uid, uid_type)
    conv = Conversation.find_by(merchant_id: merchant_id, uid_type: uid_type, uid: uid)
    return [] unless conv

    conv_ref_ids = conv.conversation_resolutions.where("uid_conversation_ref_id is not null or uid_conversation_ref_id != ''").pluck(:uid_conversation_ref_id)
    ConversationRef.includes(:textable).where(id: conv_ref_ids).order(created_at: :desc)
  end
end
