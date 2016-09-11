class BankAccount < ActiveRecord::Base

  belongs_to :user

  attr_accessor :account_number, :institution_number
end
