class Api::V1::IntelligenceController < Api::V1::BaseController
  skip_before_action :verify_authenticity_token
    
  def index
    begin
      render json: { response: 'Incomplete parameters' }, status: bad_request and return unless validate_params
      api_cred = ApiCred.find_by(key: params[:key], secret: params[:secret])
      render json: { response: 'Invalid key/secret' }, status: :unauthorized and return unless api_cred
      
      data = query_model
      if data.blank?
        calls = request_hash[input_type(params[:query])].second
        calls[0].constantize.public_send(calls[1], params[:query])
        data = query_model
      end

      render json: data
    rescue StandardError => exception
      ExceptionNotifier.notify_exception(exception, env: Rails.env, data: { message: "In api IntelligenceController index" })
      render json: { response: "Something went wrong" }, status: :internal_server_error
    end
  end

  private
    
  def input_type(input)
    :phone_number if Float(input) rescue :email
  end

  def request_hash
    { 
      phone_number: [["OpenCnamData", "get_opencnam_info_json_for"], ["OpenCnamService", "get_opencnam_info"]],
      email: [["FullContactData", "get_fullcontact_info_json_for"], ["FullContactService", "get_fullcontact_info"]] 
    }
  end

  def query_model
    calls = request_hash[input_type(params[:query])].first
    calls[0].constantize.public_send(calls[1], params[:query])
  end

  def validate_params 
    params.key?(:query) && params.key?(:key) && params.key?(:secret)
  end
end