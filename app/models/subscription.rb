class Subscription < ActiveRecord::Base

  belongs_to :plan
  belongs_to :coupon
  belongs_to :merchant_customer
  has_many :invoices
  has_many :notification_logs, as: :notifiable, dependent: :destroy

  validates_presence_of :plan_id, :merchant_customer_id, :quantity
  validates_numericality_of :quantity, greater_than: 0, only_integer: true

  def create_subscription(hash)
    begin
      return [false] if !self.save

      res = []
      team = hash[:team]
      is_platform = team.is_platform?
      uid = team.uid

      hash[:application_fee_percent] = Rails.application.secrets.application_fee_percent unless is_platform
      
      if self.coupon_id.present?
        coupon = Coupon.find_by(id: self.coupon_id)
        hash[:coupon] = coupon.stripe_coupon_id 
      end
      
      merchant_customer = MerchantCustomer.find self.merchant_customer_id
      hash[:customer] = merchant_customer.stripe_customer_id
      hash[:plan] = self.plan_id
      hash[:quantity] = self.quantity
      hash[:tax_percent] = hash[:team].tax_percent
      hash.delete(:team)

      return [true] 
      res = PaymentService.create_subscription(hash, uid, is_platform)
      if res.first
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
        # notify team via email
        # should this be for only standard error caught?
        self.cancel_subscription(team, false)
      end
      res
    rescue StandardError => e
      # if StandardError happened after Stripe was called, delete subscription on Stripe
      self.cancel_subscription(team, false) if res.length > 0
      # notify team via email
      [false]
    end
  end

  def cancel_subscription(team, at_period_end = true)
    begin
      res = PaymentService.cancel_subscription(self.stripe_subscription_id, team.uid, team.is_platform?, at_period_end)
      if res.first && self.update(status: res.second.status, cancel_at_period_end: res.second.cancel_at_period_end)
        true
      else
        # notify team via email
        false
      end
    rescue StandardError => e
      # notify team via email
      false
    end
  end

  def unused_amount
    plan = self.plan
    plan_amt = plan.amount
    coupon_amt = 0

    # calculate coupon amount
    coupon = self.coupon
    if coupon.present?
      if coupon.amount_off.present?
        coupon_amt = plan_amt - coupon.amount_off
      else
        coupon_amt = plan_amt - (coupon.percent_off/100.to_f * plan_amt).round(2)
      end
    end

    # amount after coupon discount
    plan_amt = plan_amt - coupon_amt

    # calculate number of days from subscription start to subscription end
    # stripe most likely stores time in UTC
    start_date = DateTime.strptime(self.current_period_start.to_s,'%s')
    end_date = DateTime.strptime(self.current_period_end.to_s,'%s')
    total_days = (end_date - start_date).to_i + 1  # +1 to include the start day

    days_remaining = (end_date - DateTime.now.utc).to_i + 1
    days_remaining = (days_remaining > 0) ? days_remaining : 0

    plan_amt = (plan_amt.to_f / total_days).round(2)            # plan amount per day
    ((plan_amt * days_remaining)).round                 # unspent amount (prorated per day)
  end

end
