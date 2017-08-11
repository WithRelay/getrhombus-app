# Save Invoices
class Invoice < ActiveRecord::Base
  belongs_to :subscription
  belongs_to :coupon
  # belongs_to :merchant_customer
end
