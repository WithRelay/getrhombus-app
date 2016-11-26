class BankAccount < ActiveRecord::Base
  belongs_to :user

  # validation rules
  validates_presence_of :stripe_bank_account_id, :country, :bank_name, :account_number, :currency,
                        :default_for_currency, :fingerprint
end
