class TransactionFee < ActiveRecord::Base
 
  has_many :stripe_creds
  has_many :transactions

  enum fee_type: [:platform, :merchant]

end