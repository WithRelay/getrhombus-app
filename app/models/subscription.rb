class Subscription < ActiveRecord::Base

  belongs_to :plans
  belongs_to :user
  belongs_to :coupons
  belongs_to :team, class_name: "User"
  has_many :notification_log, as: :notifiable, dependent: :destroy

  validates_presence_of :plan_id, :user_id

  def create_subscription(hash)
    begin
      res = []
      team = hash[:team]
      is_platform = team.is_platform?
      uid = team.uid

      hash[:application_fee_percent] = Rails.application.secrets.application_fee_percent unless is_platform

      coupon = Coupon.find_by(id: self.coupon_id) if self.coupon_id.present?
      # check coupon validity
      # only use coupons for subscription if coupon is not_expired/valid
      if coupon && PaymentService.is_valid_coupon(coupon.stripe_coupon_id)
          hash[:coupon] = coupon.stripe_coupon_id
      end
      # Using only customer_uri since we support only 1 card and this
      # way if a customer changes the card on file we don't need to change the subscription source
      hash[:customer] = hash[:customer]
      #hash[:source]
      hash[:plan] = self.plan_id
      hash[:quantity] = self.quantity
      hash[:tax_percent] = hash[:team].tax_percent
      # No need to override trial end in plan
      #hash[:trial_end]

      hash.delete(:team)
      res = PaymentService.create_subscription(hash, uid, is_platform)

      if res.first
        # save customer data to MerchantCustomer
        MerchantCustomer.create(merchant_id: team.id , customer_id: res.last)
        self.update(
          stripe_subscription_id: res.second.id,
          status: res.second.status,
          stripe_livemode: res.second.livemode,
          trial_end: res.second.trial_end,
          trial_start: res.second.trial_start,
          current_period_start: res.second.current_period_start,
          current_period_end: res.second.current_period_end,
          canceled_at: res.second.canceled_at,
          cancel_at_period_end: res.second.cancel_at_period_end,
          ended_at: res.second.ended_at
        )
      else
        #notify team via email
      end

      res.first
    rescue StandardError => e
      # if StandardError happened after Stripe was called, delete plan on Stripe
      self.cancel_subscription if res.length > 0
      # notify team via email
    end
  end

  def cancel_subscription
    begin
      re = PaymentService.cancel_subscription(self.stripe_subscription_id, self.trial_end)
    rescue StandardError => e
      # notify team via email
      false
    end
  end

end
