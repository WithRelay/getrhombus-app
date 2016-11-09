class MerchantCustomer < ActiveRecord::Base
  belongs_to :merchant_id, class_name: "User"
  belongs_to :customer_id, class_name: "User"
end

