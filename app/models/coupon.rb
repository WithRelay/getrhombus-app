class Coupon < ActiveRecord::Base

  has_many :subscriptions
  belongs_to :user

  attr_accessor :coupon_type
  validates :name, uniqueness: { case_sensitive: false, scope: :user_id }

  def create_coupon(hash)

    uid = hash[:team].uid
    hash[:currency] = hash[:team].currency
    hash.delete(:team)

    hash[:duration] = self.duration
    # amount_off is in cent
    hash[:amount_off] = 100 * self.amount_off if  self.amount_off
    hash[:duration_in_months] = self.duration_in_months
    hash[:max_redemptions] = self.max_redemptions
    hash[:percent_off] = self.percent_off
    hash[:redeem_by] = self.redeem_by

    PaymentService.create_coupon(hash)

    # save data including stripe id
    # send emails
  end

end
