class MerchantCustomer < ActiveRecord::Base

  # platform_stripe_customer_id is the shared id between the platform and merchant standalone account
  # managed_stripe_customer_id is for the merchant managed account

  belongs_to :merchant, class_name: "User"
  belongs_to :customer, class_name: "User"
  has_many :subscriptions, inverse_of: :merchant_customer
  # has_many :invoices

  def self.add_or_update_merchant_customer(merchant_ids, customer_id)
    begin
      merchant_ids.each do |mid|
        where(merchant_id: mid, customer_id: customer_id).first_or_initialize.tap { |row| row.save }
      end
    rescue StandardError => err
    end
  end
end

