class ConversationResolution < ActiveRecord::Base

  belongs_to :merchant_conversation_ref, class_name: 'ConversationRef'
  belongs_to :uid_conversation_ref, class_name: 'ConversationRef'
  belongs_to :conversation
  belongs_to :merchant, class_name: 'User'

  def self.total_minutes_to_resolve_conversations(merchant_id)
    ConversationResolution.where(merchant_id: merchant_id).where.not(resolution: nil)
          .select("SUM(TIMESTAMPDIFF(MINUTE, created_at, updated_at)) as minutes_diff_total")
          .select('count(*) as count').first
  end
  
end