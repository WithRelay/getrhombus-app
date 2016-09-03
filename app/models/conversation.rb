class Conversation < ActiveRecord::Base
  has_many :conversation_ref, dependent: :destroy
  has_many :fb_message, through: :conversation_ref, source: :textable, source_type: 'FbMessage', dependent: :destroy
  has_many :message, through: :conversation_ref, source: :textable, source_type: 'Message', dependent: :destroy

end