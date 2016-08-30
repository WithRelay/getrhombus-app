class Hashtag < ActiveRecord::Base
	
	## help add index to tag together with user_id

	belongs_to :user

  # test this again
  has_many :image_refs, as: :imageable, dependent: :destroy
  has_many :images, through: :image_refs, dependent: :destroy

	# validations
	validates :tag, presence: true, uniqueness: { case_sensitive: false }
	validates :amount, presence: true, numericality: true, :if => lambda { self.tag_type != 1 }

  accepts_nested_attributes_for :images


end
