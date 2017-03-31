class ConversationRef < ActiveRecord::Base

  belongs_to :textable, :polymorphic => true
  belongs_to :conversation
  has_one :merchant_conversation_resolution, class_name: 'ConversationResolution', foreign_key: 'merchant_conversation_ref_id'
  has_one :uid_conversation_resolution, class_name: 'ConversationResolution', foreign_key: 'uid_conversation_ref_id'

  enum source: { platform: 0, merchant: 1, customer: 2, campaign: 3 }

  # the last message in all conversations within a thread between a merchant and customer
  def self.get_last_customer_msg_from_all_merchant_convs(merchant_id, customer_id)
    conv = Conversation.find_by(merchant_id: merchant_id, uid_type: 'user', uid: customer_id)
    return [] unless conv
    conv_ref_ids = conv.conversation_resolutions.pluck(:uid_conversation_ref_id)
    ConversationRef.includes(:textable).where(id: conv_ref_ids).order(created_at: :desc)
  end

=begin
  # the last message in all conversations a merchant has had
  def self.get_last_msgs_from_all_merchant_convs(merchant_id)
    data = find_by_sql(["SELECT a.id, a.textable_id, a.textable_type, b.uid, b.uid_type, a.created_at as created_at
                          FROM conversation_refs a
                          INNER JOIN (
                           SELECT max(c.id) as id, e.uid as uid, e.uid_type as uid_type
                           FROM conversation_refs c
                           INNER JOIN (
                            SELECT id, uid, uid_type FROM conversations d
                            where d.merchant_id = ? and d.is_resolved is false
                            order by d.updated_at desc, id desc
                            ) e ON e.id = c.conversation_id
                           where source = 2 and unread = 1 GROUP BY c.conversation_id limit 5
                          ) b ON a.id = b.id order by a.created_at desc, id desc", merchant_id])

    return [] if data.blank?
    ActiveRecord::Associations::Preloader.new.preload(data, :textable)
    data
  end
=end

  # get all unread messages for which the merchant hasn't received an unread notification
  def self.get_merchant_total_unread_messages_not_notified(merchant_id)
    data = find_by_sql(["select cr.id as id, cr.created_at as created_at, textable_id, textable_type, uid, uid_type
                          from conversations c inner join conversation_refs cr
                          on c.id = cr.conversation_id
                          where cr.unread = 1 and c.is_resolved is false
                          and cr.unread_notification_sent = 0
                          and c.merchant_id = ? and cr.source = 2
                          order by cr.created_at desc", merchant_id])
    return [] if data.blank?
    ActiveRecord::Associations::Preloader.new.preload(data[0..2], :textable)
    data
  end



end