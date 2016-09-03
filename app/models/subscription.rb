class Subscription < ActiveRecord::Base

  belongs_to :plans
  belongs_to :user
  belongs_to :coupons
  belongs_to :team, class_name: "User"

  def create_subscription(hash)

    uid = hash[:team].uid

    hash[:application_fee_percent] = Rails.application.secrets.application_fee_percent
    hash[:coupon] = Coupon.find_by(id: self.coupon_id).id if self.coupon_id.present?
    hash[:customer] = hash[:customer].customer_uri
    hash[:plan] = self.plan_id  
    #hash[:source]
    hash[:quantity] = self.quantity
    hash[:tax_percent] = hash[:team].tax_percent
    #hash[:trial_end]

    hash.delete(:team)

    #re = PaymentService(hash, uid)

    # save data
    # send emails

    self.save
    self.id
  end

  def cancel_subscription(at_trial_end)
    
    #re = PaymentService(self.stripe_subscription_id, at_trial_end)

    # save data
    # send emails    

  end


end
