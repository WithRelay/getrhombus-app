class BankAccount < ActiveRecord::Base
  belongs_to :user
  attr_accessor :account_number_confirmation  
  validates_presence_of :country, :account_number
  validates_confirmation_of :account_number
end
