# Save Invoices
class Invoice < ActiveRecord::Base
  belongs_to :coupon
  belongs_to :subscription
  belongs_to :transaction_fee
  belongs_to :team, class_name: :User
  belongs_to :customer, class_name: :User  
end
