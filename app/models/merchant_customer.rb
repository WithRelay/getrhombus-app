class MerchantCustomer < ActiveRecord::Base
  belongs_to :merchant, class_name: "User"
  belongs_to :customer, class_name: "User"
  has_many :subscriptions, inverse_of: :merchant_customer
  # has_many :invoices


  #def self.add_to
  # check that the ids are unique...no duplicate records or will first_or_initalize catch it anyway
end

