module Transactionable
  extend ActiveSupport::Concern

  def generate_number
    random_token = nil
    loop do
      # http://stackoverflow.com/questions/88311/how-best-to-generate-a-random-string-in-ruby?rq=1
      random_token = Toolbox::StringGen.generate_random_string(6)
      break unless Transaction.unscoped.exists?(transaction_number: random_token)
    end
    random_token
  end
end