class TransactionFee < ActiveRecord::Base
 
  has_many :stripe_creds
  has_many :transactions

  enum fee_type: [:platform, :merchant]

  # amt in integer
  def self.amount_with_taxes(amt, tax_percent)
    (amt.to_f * ((tax_percent.to_f/100) + 1)).round
  end

end