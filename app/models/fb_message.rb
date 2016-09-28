class FbMessage < ActiveRecord::Base
  # for conversation
	has_many :conversation_refs, as: :textable, dependent: :destroy
  has_many :conversations, through: :conversation_refs
  
  belongs_to :fb_page

  # for image table relation
  has_many :image_refs, as: :imageable, dependent: :destroy
  has_many :images, through: :image_refs
  
  validates :message_id, uniqueness: true
end
