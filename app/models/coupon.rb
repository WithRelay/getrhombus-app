class Coupon < ActiveRecord::Base

  has_many :subscriptions
  belongs_to :user

  attr_accessor :coupon_type
  validates :name, uniqueness: { scope: :user_id }

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
end
