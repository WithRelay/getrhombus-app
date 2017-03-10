class ConversationRef < ActiveRecord::Base

  belongs_to :textable, :polymorphic => true
  belongs_to :conversation

  enum source: { platform: 0, merchant: 1, customer: 2 }

  def self.find_last_conversation_ref(conv)
  	conv.blank? ? nil : conv.conversation_refs.last
  end

  def self.get_last_customer_msg_from_all_merchant_convs(merchant_id, customer_id)
    data = find_by_sql(["SELECT a.id, a.textable_id, a.textable_type, b.uid, b.uid_type, a.created_at as created_at,
                          CASE WHEN a.textable_type = 'Message' THEN 'SMS' ELSE 'messenger' END as channel,
                          b.resolution as resolution
                          FROM conversation_refs a
                          INNER JOIN (
                           SELECT max(c.id) as id, e.uid as uid, e.uid_type as uid_type, e.resolution as resolution
                           FROM conversation_refs c
                           INNER JOIN (
                            SELECT id, uid, uid_type, resolution from conversations d
                            where d.merchant_id = ? and uid_type = 'user'
                            and uid = ? order by d.created_at desc, id desc
                            ) e ON e.id = c.conversation_id
                           where source = 2 GROUP BY c.conversation_id 
                          ) b ON a.id = b.id order by a.created_at desc, id desc", merchant_id, customer_id])

    return [] if data.blank?
    ActiveRecord::Associations::Preloader.new.preload(data, :textable)
    data
  end  

  def self.get_last_msgs_from_all_merchant_convs(merchant_id)
    data = find_by_sql(["SELECT a.id, a.textable_id, a.textable_type, b.uid, b.uid_type, a.created_at as created_at
                          FROM conversation_refs a
                          INNER JOIN (
                           SELECT max(c.id) as id, e.uid as uid, e.uid_type as uid_type
                           FROM conversation_refs c
                           INNER JOIN (
                            SELECT id, uid, uid_type FROM conversations d
                            where d.merchant_id = ? and d.resolution is null or 
                      			d.resolution = '' order by d.created_at desc, id desc
                            ) e ON e.id = c.conversation_id
                           where source = 2 and unread = 1 GROUP BY c.conversation_id limit 5
                          ) b ON a.id = b.id order by a.created_at desc, id desc", merchant_id])

    return [] if data.blank?
    ActiveRecord::Associations::Preloader.new.preload(data, :textable)
    data
  end  
  
  
end