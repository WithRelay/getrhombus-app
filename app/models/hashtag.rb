class Hashtag < ActiveRecord::Base
	
	# add index to tag together with user_id

	belongs_to :user

	# validations
	validates :name, :response, presence: true
	validates :tag, presence: true, uniqueness: { case_sensitive: false }
	validates :amount, presence: true, numericality: true, :if => lambda { self.not_payment_tag == 0 }

end
