# ApiCredController

class Api::V1::ApiCredController < Api::V1::BaseController
  def generate_key
    api_cred = ApiCred.find_or_create_by(user_id: current_user.id)
    response = api_cred.update(api_key: api_cred.generate_api_key, api_secret: api_cred.generate_api_secret)
    render json: { response: response, key: api_cred.api_key, secret: api_cred.api_secret }, status: 200
  end
end
