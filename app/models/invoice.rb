# Save Invoices
class Invoice < ActiveRecord::Base
  belongs_to :coupon
  belongs_to :subscription
  belongs_to :transaction_fee
  belongs_to :team, class_name: :User
  belongs_to :customer, class_name: :User

  def taxes
    Toolbox::Decimal.cents_to_int_or_2dp(tax.to_f)
  end

  def fees
    Toolbox::Decimal.cents_to_int_or_2dp(application_fee.to_f)
  end
end
