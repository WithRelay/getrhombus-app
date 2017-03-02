class ConversationRef < ActiveRecord::Base

  belongs_to :textable, :polymorphic => true
  belongs_to :conversation

  enum source: { platform: 0, merchant: 1, customer: 2 }

  def self.find_last_conversation_ref(conv)
  	conv.blank? ? nil : conv.conversation_refs.last
  end

   def self.get_last_customer_msg_from_all_merchant_convs(merchant_id)
    data = ConversationRef.find_by_sql(["SELECT a.id, a.textable_id, a.textable_type, b.uid, b.uid_type, a.created_at as created_at,
		                                      CASE WHEN a.textable_type = 'Message' THEN 'SMS' ELSE 'messenger' END as channel,
		                                      b.resolution as resolution
		                                      FROM conversation_refs a
		                                      INNER JOIN (
		                                       SELECT max(c.id) as id, e.uid as uid, e.uid_type as uid_type, e.resolution as resolution
		                                       FROM conversation_refs c
		                                       INNER JOIN (
		                                        SELECT id, uid, uid_type, resolution from conversations d
		                                        where d.merchant_id = ? order by d.created_at desc
		                                        ) e ON e.id = c.conversation_id
		                                       where source = 2 GROUP BY c.conversation_id 
		                                      ) b ON a.id = b.id", merchant_id])

    return [] if data.blank?
    ActiveRecord::Associations::Preloader.new.preload(data, :textable)
    data
  end  
  
end