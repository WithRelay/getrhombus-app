class MerchantCustomer < ActiveRecord::Base
  belongs_to :merchant, class_name: "User"
  belongs_to :customer, class_name: "User"
  has_one :subscription
end

