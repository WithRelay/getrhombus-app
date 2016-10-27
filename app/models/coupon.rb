class Coupon < ActiveRecord::Base

  has_many :subscriptions
  belongs_to :user

  attr_accessor :coupon_type
  validates_presence_of :name
  validates :name, uniqueness: { case_sensitive: false, scope: :user_id }
  validate :persent_or_amount

  def create_coupon(hash)

    uid = hash[:team].uid
    hash[:currency] = hash[:team].currency
    hash.delete(:team)

    hash[:duration] = self.duration
    hash[:amount_off] = self.amount_off
    hash[:duration_in_months] = self.duration_in_months
    hash[:max_redemptions] = self.max_redemptions
    hash[:percent_off] = self.percent_off
    hash[:redeem_by] = self.redeem_by

    #re = PaymentService.create_coupon(hash, uid)

    # save data including stripe id
    # send emails

    self.save
    self.id
  end

  # Must provide percent_off or amount_off.
  def persent_or_amount
    if percent_off.blank? && amount_off.blank?
      errors[:base] = "Must provide percent_off or amount_off."
    end
  end
end
