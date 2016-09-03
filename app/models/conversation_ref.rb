class ConversationRef < ActiveRecord::Base

  belongs_to :textable, :polymorphic => true
  belongs_to :conversation
  
end