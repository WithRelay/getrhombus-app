class Hashtag < ActiveRecord::Base

	belongs_to :user

  attr_accessor :skip_tag_validation

  # test this again
  has_many :image_refs, as: :imageable, dependent: :destroy
  has_many :images, through: :image_refs
  
  has_many :messages
  belongs_to :txn, foreign_key: :hashtag_id, class_name: :Transaction
  has_one :plan

	# validations
	validates :tag, presence: true, uniqueness: { case_sensitive: false, scope: :user_id }, unless: :skip_tag_validation
  validates :name, presence: true, uniqueness: { case_sensitive: false, scope: :user_id }
	validates :amount, presence: true, numericality: true, unless: lambda { self.non_payment_tag? }
  validates :response, length: { maximum: 320 }
  validate :amount_greater_than_15000

  enum tag_type: { non_payment_tag: 0, one_time_payment_tag: 1, recurring_payment_tag: 2 }
  enum status: { inactive: 0, active: 1 }
  enum charge_amount: { allow_customers_to_override_amount: 0, always_charge_amount: 1 }

  accepts_nested_attributes_for :images

  # You need a new plan if this is the first time
  # or any recurring hashtag detail changes on update
  def create_new_plan_and_subscription
    if true
    end
  end


  def mentions_count
    # because hashtag_id will exist in a transaction that was created by a text message. so avoid duplicates
    in_txns_not_in_msg_count = Hashtag.find_by_sql(["SELECT count(*) as count FROM transactions t LEFT JOIN messages m
                                          on m.transaction_id = t.id
                                          WHERE t.hashtag_id = ? and m.transaction_id IS NULL", self.id]).first.count
    in_txns_not_in_fb_msg_count = Hashtag.find_by_sql(["SELECT count(*) as count FROM transactions t LEFT JOIN fb_messages f
                                          on f.transaction_id = t.id
                                          WHERE t.hashtag_id = ? and f.transaction_id IS NULL", self.id]).first.count
    in_fb_msg_count = FbMessage.where(hashtag_id: self.id).count
    in_msg_count = Message.where(hashtag_id: self.id).count

    in_txns_not_in_msg_count + in_txns_not_in_fb_msg_count + in_fb_msg_count + in_msg_count
  end

  def is_mentioned?
    self.mentions_count > 0
  end

  def delete_recurring_plan(merchant)
    return [true] if !self.recurring_payment_tag?
    plan = Plan.find_by(customer_id: nil, merchant_id: merchant.id, hashtag_id: self.id, active: 1)
    return [true] if plan.blank?
    if plan.plan_has_subscription? 
      return [true] if plan.delete_plan(merchant) && plan.destroy
      [false, 'We cannot delete this hashtag because we cannot delete the associated recurring plan.'] 
    else
      [false, 'We cannot delete this hashtag because it has a plan that has a subscription.']
    end
  end


  private

    def amount_greater_than_15000
      errors.add(:amount, "can't be greater than 15000") if !self.non_payment_tag? && Toolbox::Decimal.to_cents(self.amount) > 1500000
    end
end
