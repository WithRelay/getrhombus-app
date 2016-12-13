class Coupon < ActiveRecord::Base

  has_many :subscriptions
  has_many :invoices
  belongs_to :user

  attr_accessor :coupon_type
  validates_presence_of :name
  validates :name, uniqueness: { case_sensitive: false, scope: :user_id }
  
  validates_presence_of :duration
  
  validates_presence_of :duration_in_months, if: lambda { self.duration == "repeating" }
  validates :duration_in_months, numericality: { allow_blank: true, greater_than: 0, only_integer: true }
  
  validates_presence_of :percent_off, if: lambda { self.amount_off.blank? }
  validates :percent_off, numericality: { allow_blank: true, greater_than: 0, less_than: 101, only_integer: true }

  validates_presence_of :amount_off, if: lambda { self.percent_off.blank? }
  validates :amount_off, :max_redemptions, numericality: { allow_blank: true, greater_than: 0, only_integer: true }

  validate :validate_redeem_by

  def create_coupon(hash)
    begin
      res = []

      hash[:duration] = self.duration
      # amount_off is in cent
      hash[:amount_off] = self.amount_off
      hash[:duration_in_months] = self.duration_in_months
      hash[:max_redemptions] = self.max_redemptions
      hash[:percent_off] = self.percent_off
      hash[:redeem_by] = self.redeem_by
      hash[:currency] = hash[:team].currency

      # Update so validations run before calling Stripe
      self.update(user_id: hash[:team].id, currency: hash[:team].currency)
      hash.delete(:team)

      res = PaymentService.create_coupon(hash)
      if res.first && self.update(stripe_livemode: res.second.livemode, stripe_coupon_id: res.second.id)
        true
      else
        #notify team via email
        # if StandardError happens in create_coupon after Stripe was called or update fails above
        self.delete_coupon
        false        
      end

    rescue StandardError => e
      # if StandardError happened after Stripe was called, delete plan on Stripe
      self.delete_coupon if res.length > 0
      # notify team via email
      false
    end
  end

  def delete_coupon
    begin
      PaymentService.delete_coupon(self.stripe_coupon_id).first
    rescue StandardError => e
      # notify team via email
      false
    end
  end

  # check coupon validity - only use coupons for subscription if coupon is not_expired/valid
  def is_valid?
    PaymentService.is_valid_coupon(self.stripe_coupon_id)
  end

  private

  def validate_redeem_by
    if (Time.current) > (Time.at(self.redeem_by))
      errors.add(:redeem_by, 'can\'t be less than current date_time')
    elsif (Time.current + 4.years) <= (Time.at(self.redeem_by))
      errors.add(:redeem_by, 'can\'t be greater than 5 years from current date time')
    end
   end
end
