class ConversationRef < ActiveRecord::Base

  belongs_to :textable, :polymorphic => true
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

  # get all unread messages for which the merchant hasn't received an unread notification
  def self.get_merchant_total_unread_messages_not_notified(merchant_id)
    data = find_by_sql(["select cr.id as id, cr.created_at as created_at, textable_id, textable_type, uid, uid_type
                          from conversations c inner join conversation_refs cr
                          on c.id = cr.conversation_id
                          where cr.unread = 1 and c.is_resolved is false
                          and cr.unread_notification_sent = 0
                          and c.merchant_id = ? and cr.source = #{ConversationRef.sources[:customer]}
                          order by cr.created_at desc", merchant_id])
    return [] if data.blank?
    ActiveRecord::Associations::Preloader.new.preload(data[0..2], :textable)
    data
  end



end