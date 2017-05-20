class BankAccount < ActiveRecord::Base
  belongs_to :user
  attr_accessor :account_number_confirmation
end
