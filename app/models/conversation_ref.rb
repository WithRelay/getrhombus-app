class ConversationRef < ActiveRecord::Base

  belongs_to :textable, :polymorphic => true
  belongs_to :conversation

  enum source: { platform: 0, merchant: 1, customer: 2 }
  
end