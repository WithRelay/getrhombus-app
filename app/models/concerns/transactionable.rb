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

  def generate_uid
    random_token = ''
    loop do
      # http://stackoverflow.com/questions/88311/how-best-to-generate-a-random-string-in-ruby?rq=1
      random_token = Toolbox::StringGen.generate_random_string(8)
      break unless User.unscoped.exists?(relay_uid: random_token)
    end
    random_token
  end

  def generate_resource_name(model)
    random_token = nil
    loop do
      random_token = model + "-" + Toolbox::StringGen.generate_random_string(6)
      break unless model.constantize.unscoped.exists?(name: random_token)
    end
    random_token
  end

   # Generate a unique API key
  def generate_api_key
    token = nil
    loop do
      token = SecureRandom.base64.tr('+/=', 'Qrt')
      break unless ApiCred.unscoped.exists?(key: token)
    end
    token
  end

  # Generate a unique API secret
  def generate_api_secret
    token = nil
    loop do
      token = SecureRandom.base64.tr('+/=', 'Qrt')
      break unless ApiCred.unscoped.exists?(secret: token)
    end
    token
  end
end