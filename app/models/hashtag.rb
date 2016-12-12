class Hashtag < ActiveRecord::Base

	belongs_to :user

  # test this again
  has_many :image_refs, as: :imageable, dependent: :destroy
  has_many :images, through: :image_refs
  
  has_many :messages
  belongs_to :txn, :foreign_key => :hashtag_id, :class_name => :Transaction


	# validations
	validates :tag, presence: true, uniqueness: { case_sensitive: false, scope: :user_id }
	validates :amount, presence: true, numericality: true, :if => lambda { !self.non_payment_tag? }

  enum tag_type: { non_payment_tag: 0, one_time_payment_tag: 1, recurring_payment_tag: 2 }
  enum charge_amount: { allow_customers_to_override_amount: 0, always_charge_amount: 1 }

  accepts_nested_attributes_for :images

  # You need a new plan if this is the first time
  # or any recurring hashtag detail changes on update
  def create_new_plan_and_subscription
    if true

      

    end
  end



end
