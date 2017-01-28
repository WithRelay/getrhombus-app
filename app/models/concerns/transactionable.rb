module Transactionable
  extend ActiveSupport::Concern

  def generate_txn_number
    random_token = nil
    loop do
      # http://stackoverflow.com/questions/88311/how-best-to-generate-a-random-string-in-ruby?rq=1
      random_token = Toolbox::StringGen.generate_random_string(8)
      break unless Transaction.unscoped.exists?(txn_number: random_token)
    end
    random_token
  end

  def self.generate_uid
    random_token = ''
    loop do
      # http://stackoverflow.com/questions/88311/how-best-to-generate-a-random-string-in-ruby?rq=1
      random_token = Toolbox::StringGen.generate_random_string(8)
      break unless Referrer.unscoped.exists?(uid: random_token)
    end
    random_token
  end

  def generate_resource_name(model)
    random_token = nil
    loop do
      random_token = model + "-" + Toolbox::StringGen.generate_random_string(8)
      break unless model.constantize.unscoped.exists?(name: random_token)
    end
    random_token
  end
end