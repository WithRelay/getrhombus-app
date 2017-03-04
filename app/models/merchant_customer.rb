class MerchantCustomer < ActiveRecord::Base
  belongs_to :merchant, class_name: "User"
  belongs_to :customer, class_name: "User"
  has_many :subscriptions, inverse_of: :merchant_customer
  has_many :transactions
  # has_many :invoices
end

