module Transactionable
  extend ActiveSupport::Concern

  protected

  def generate_number
    random_number = nil
    loop do
      random_token = SecureRandom.hex(4)
      #break unless self.class.exists?(transaction_number: random_token)
      break unless Transaction.unscoped.exists?(transaction_number: random_token)
    end
    random_number
end