class Api::V1::MessagesController < Api::V1::BaseController
  skip_before_action :verify_authenticity_token, only: [:send_message]

  def send_message
    binding.pry
    api_cred = ApiCred.find_by(key: params[:key], secret: params[:secret])
    if api_cred
      merchant = api_cred.user
      all_customer_phones = params[:to].split(',').map(&:strip)
      all_customer_phones.each do |phone_number|
        customer = User.find_by(phone_number: phone_number)
        if customer.present?
          uid, uid_type = customer.id, 'user'
          MerchantCustomer.add_or_update_merchant_customer(merchant, customer)
        else
          uid, uid_type = params[:to], 'phone_number'
          MerchantContact.add_or_update_merchant_contact(merchant.id, uid, uid_type)
          OpenCnamData.find_record_or_get_intelligence_data(uid)
        end

        conv = Conversation.find_or_create_conversation(merchant.id, uid, uid_type)
        Conversation.send_message(conv, merchant, params[:body], 'platform', [])
      end
      response = 'Success'
      status = 200
    else
      response = 'Invalid key/secret'
      status = 500
    end

    render json: { response: response }, status: status
  rescue StandardError => exception
    ExceptionNotifier.notify_exception(exception, env: Rails.env, data: { message: "In api messages send" })
  end

end
