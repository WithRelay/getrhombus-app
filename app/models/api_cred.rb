# Api credentials table
class ApiCred < ActiveRecord::Base
  belongs_to :users
  # Assign an API key and secret on create

  private

  # Generate a unique API key
  def generate_api_key
    loop do
      token = SecureRandom.base64.tr('+/=', 'Qrt')
      break token unless ApiCred.exists?(api_key: token)
    end
  end

  # Generate a unique API secret
  def generate_api_secret
    loop do
      token = SecureRandom.base64.tr('+/=', 'Qrt')
      break token unless ApiCred.exists?(api_secret: token)
    end
  end
end
