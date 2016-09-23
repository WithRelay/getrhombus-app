class FbMessage < ActiveRecord::Base
	has_many :conversation_refs, as: :textable, dependent: :destroy
  has_many :conversations, through: :conversation_refs, dependent: :destroy
  belongs_to :fb_page
end
