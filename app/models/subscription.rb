class Subscription < ActiveRecord::Base

  belongs_to :plans
  belongs_to :coupons
  belongs_to :merchant_customer
  has_many :notification_logs, as: :notifiable, dependent: :destroy

  validates_presence_of :plan_id, :merchant_customer_id

  def create_subscription(hash)
    begin
      res = []
      team = hash[:team]
      is_platform = team.is_platform?
      uid = team.uid

      hash[:application_fee_percent] = Rails.application.secrets.application_fee_percent unless is_platform
      
      coupon = Coupon.find_by(id: self.coupon_id) if self.coupon_id.present?
      # check coupon validity - only use coupons for subscription if coupon is not_expired/valid      
      hash[:coupon] = coupon.stripe_coupon_id if coupon && PaymentService.is_valid_coupon(coupon.stripe_coupon_id)   
      
      hash[:plan] = self.plan_id
      hash[:quantity] = self.quantity
      hash[:tax_percent] = hash[:team].tax_percent      
      hash.delete(:team)

      res = PaymentService.create_subscription(hash, uid, is_platform)
      
      if res.first
        # save customer data to MerchantCustomer
        merchant_customer = MerchantCustomer.create(
          merchant_id: team.id ,
          customer_id: self.merchant_customer_id,
          stripe_customer_id: res.second.customer
         )
        self.update(
          merchant_customer_id: merchant_customer.id,
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
      self.cancel_subscription(team) if res.length > 0
      # notify team via email
    end
  end

  def cancel_subscription(team)
    begin
      PaymentService.cancel_subscription(self.stripe_subscription_id, team.uid, team.is_platform?)
    rescue StandardError => e
      # notify team via email
      [false, e]
    end
  end

end
