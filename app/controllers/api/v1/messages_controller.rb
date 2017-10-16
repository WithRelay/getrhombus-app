class Api::V1::MessagesController < Api::V1::BaseController
  skip_before_action :verify_authenticity_token, only: [:send_message]

  def send_message
    begin
      render json: { response: 'Incomplete parameters' }, status: :bad_request and return unless validate_params
      api_cred = ApiCred.includes(:user).find_by(key: params[:key], secret: params[:secret])
      render json: { response: 'Invalid key/secret' }, status: :unauthorized and return unless api_cred
      
      
      merchant = api_cred.user
      all_customer_phones = params[:to].split(',').map(&:strip)
      all_customer_phones.each do |phone_number|
        customer = User.find_by(phone_number: phone_number)
        if customer
          uid, uid_type = customer.id, 'user'
          MerchantCustomer.add_or_update_merchant_customer(merchant, customer)
        else
          uid, uid_type = params[:to], 'phone_number'
          MerchantContact.add_or_update_merchant_contact(merchant.id, uid, uid_type)
          OpenCnamData.find_record_or_get_intelligence_data(uid)
        end

        conv = Conversation.find_or_create_conversation(merchant.id, uid_type, uid)
        Conversation.send_message(conv, merchant, params[:body], 'Message', 'platform')
      end
      
      render json: { response: "Success" }, status: 200
    rescue StandardError => exception
      ExceptionNotifier.notify_exception(exception, env: Rails.env, data: { message: "In api messages send" })
      render json: { response: "Something went wrong" }, status: :internal_server_error
    end
  end

  private

  def validate_params 
    params.key?(:to) && params.key?(:body) && params.key?(:key) && params.key?(:secret) #|| params.key?(:from) 
  end

end
