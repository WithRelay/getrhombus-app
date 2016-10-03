class FbMessage < ActiveRecord::Base
  # for conversation
	has_one :conversation_ref, as: :textable, dependent: :destroy
  has_one :conversation, through: :conversation_refs
  
  belongs_to :fb_page

  # for image table relation
  has_many :image_refs, as: :imageable, dependent: :destroy
  has_many :images, through: :image_refs
  
  validates :message_id, uniqueness: true
end
