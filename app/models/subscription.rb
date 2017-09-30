# Subscription
class Subscription < ActiveRecord::Base
  belongs_to :plan
  belongs_to :coupon
  belongs_to :merchant_customer, inverse_of: :subscriptions

  has_many :invoices

  validates_presence_of :plan_id, :merchant_customer_id, :quantity
  validates_numericality_of :quantity, greater_than: 0, only_integer: true

  delegate :name, :interval, :amount, to: :plan, prefix: :plan, allow_nil: true
  delegate :merchant_email, :org_name, :rhombus_number, :merchant, to: :merchant_customer

  def create_subscription(hash)
    #begin
      return [false] unless self.save

      res = []
      team = hash[:team]
      is_platform = team.is_platform?
      cred = team.get_stripe_cred

      if is_platform || (team.is_merchant? && cred[:cred][:type] == 'managed')

        fee_schedule = cred[:cred].transaction_fee
        hash[:application_fee_percent] = fee_schedule.subscription_percent.to_f.round(2)
        
        if self.coupon_id.present?
          coupon = Coupon.find_by self.coupon_id
          hash[:coupon] = coupon.stripe_coupon_id if coupon
        end

        merchant_customer = MerchantCustomer.find self.merchant_customer_id

        # Need to check that customer has been added to merchant account on stripe.
        # Platform not needed since they are added when they add a card.
        unless is_platform
          if merchant_customer.managed_stripe_customer_id.blank?
            token_res = team.add_token_for_merchant_customer_from_platform_customer(merchant_customer)
            # can return a adding card error here in token_res.third...so you bubble up this specific error
            return token_res unless token_res.first
          end
        end

        # see if merchant_customer is reloaded here
        puts merchant_customer.inspect

        hash[:customer] = is_platform ? merchant_customer.platform_stripe_customer_id : merchant_customer.managed_stripe_customer_id
        hash[:plan] = self.plan_id
        hash[:quantity] = self.quantity
        hash[:tax_percent] = hash[:team].tax_percent
        hash.delete(:team)

        res = PaymentService.create_subscription(hash, cred[:cred], is_platform)

        if res.first
          self.update(
            stripe_subscription_id: res.second.id,
            transaction_fee_id: @fee_schedule.try(:id),
            tax_percent: hash[:tax_percent],
            status: res.second.status,
            stripe_livemode: res.second.livemode,
            trial_end: res.second.trial_end,
            trial_start: res.second.trial_start,
            current_period_start: res.second.current_period_start,
            current_period_end: res.second.current_period_end,
            canceled_at: res.second.canceled_at,
            cancel_at_period_end: res.second.cancel_at_period_end,
            ended_at: res.second.ended_at,
            created: res.second.created,
            start: res.second.start
          )
        else
          # notify team via email
          # in case something went wrong after we created a subscription
          self.cancel_subscription(team, false)
        end
        res
      else
        errors[:base] << "Your account doesn't support creating subscriptions."
        [false]
      end
    #rescue StandardError => e
      # if StandardError happened after Stripe was called, delete subscription on Stripe
     # self.cancel_subscription(team, false) if res.length > 0
      # notify team via email
      #[false]
    #end
  end

  def cancel_subscription(team, at_period_end = false)
    begin
      res = PaymentService.cancel_subscription(self.stripe_subscription_id, team.get_stripe_cred[:cred], team.is_platform?, at_period_end)
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

  def update_subscription(team, coupon_id)
    begin
      res = PaymentService.update_subscription(self.stripe_subscription_id, team.get_stripe_cred[:cred], team.is_platform?, coupon_id)
      if res
        coupon = Coupon.find_by(stripe_coupon_id: res[:discount][:coupon][:id])
         self.update(coupon_id: coupon.id, status: res.status, cancel_at_period_end: res.cancel_at_period_end)
        true
      else
        # notify team via email
        false
      end
    rescue StandardError => e
      false
    end
  end

  def total_amount
    self.plan_amount * self.quantity
  end

  def amount_with_taxes
    TransactionFee.amount_with_taxes(total_amount, self.tax_percent)
  end

  def description
    "Subscription payment to #{merchant_email}. #{org_name}. Rhombus number: #{rhombus_number}"
  end

  # we charge only a percent... and is it on the total amount? or no tax... stripe dont add tax
  ### should we charge on total?? or how does stripe charge then?
  def get_fees
    sbtn_merchant = merchant
    fees = get_fees_schedule(sbtn_merchant)
    { 
      stripe_fee: ((total_amount * (fees[0]/100)) + fees[1]).round, 
      app_fee: sbtn_merchant.is_platform? ? 0 : (total_amount * (fees[2]/100)).round 
    }
  end

  def get_fees_schedule(merchant)
    #@fee_schedule = merchant.is_platform? ? TransactionFee.platform.first : merchant.get_stripe_cred[:cred].transaction_fee
    fee_schedule = merchant.get_stripe_cred[:cred].transaction_fee
    [fee_schedule.provider_percent.to_f, fee_schedule.provider_cents.to_f, fee_schedule.subscription_percent.to_f]
  end

=begin
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
    plan_amt -= coupon_amt

    # calculate number of days from subscription start to subscription end
    # stripe most likely stores time in UTC
    start_date = DateTime.strptime(self.current_period_start.to_s, '%s')
    end_date = DateTime.strptime(self.current_period_end.to_s, '%s')
    total_days = (end_date - start_date).to_i + 1 # +1 to include the start day

    days_remaining = (end_date - DateTime.now.utc).to_i + 1
    days_remaining = days_remaining > 0 ? days_remaining : 0
    # plan amount per day
    plan_amt = (plan_amt.to_f / total_days).round(2)
    ((plan_amt * days_remaining)).round # unspent amount (prorated per day)
  end
=end
end
