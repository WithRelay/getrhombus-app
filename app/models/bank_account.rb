class BankAccount < ActiveRecord::Base
  belongs_to :user
  validates_presence_of :country, :account_number
end
