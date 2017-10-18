class Api::V1::ApiCredsController < Api::V1::BaseController
  skip_before_action :verify_authenticity_token

  def create
    api_cred = ApiCred.find_or_initialize_by(user_id: current_user.id)    
    if api_cred.update(key: api_cred.generate_api_key, secret: api_cred.generate_api_secret)
      response = api_cred.as_json(only: [:key, :secret])
      status = 200
    else 
      response = api_cred.errors.full_messages
      status = 500
    end

    render json: { response: response }, status: status
  end

end
