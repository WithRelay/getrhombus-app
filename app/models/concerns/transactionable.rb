module Transactionable
  extend ActiveSupport::Concern

  def generate_number
    random_token = nil
    loop do
      # random_token = SecureRandom.hex(4)          # length = 6
      #break unless self.class.exists?(transaction_number: random_token)
      # http://stackoverflow.com/questions/88311/how-best-to-generate-a-random-string-in-ruby?rq=1
      random_token = SecureRandom.random_number(36**6).to_s(36).rjust(6, "0")  
      break unless Transaction.unscoped.exists?(transaction_number: random_token)
    end
    random_token
  end
end