class Api::V1::MerchantCustomersController < API::V1::BaseController

  def index
    begin
      q = "%#{params[:query].downcase}%"
      customers =  MerchantCustomer.joins(:customer)
                  .select("merchant_customers.id, email, phone_number, card_name")
                  .where("email like ? or card_name like ? or phone_number like ?", q, q, q)
                  .where("merchant_customers.merchant_id = ?", current_user.id)

      render json: { "customers" => customers }, status: 200
    rescue StandardError => e
      render json: { error: "Unable to find your Customers" }, status: 500
    end
  end

  def create
    begin
      status = 200
      response = 'User Added'

      if params[:format] == 'csv'
        #CsvCustomerImportJob.perform_later(current_user, params['csv'].tempfile)
        #response = "CSV file uploaded."
        response = current_user.upload_customer_csv(params['csv'].tempfile)
      elsif params[:format] == 'json'
        @customer = User.find_by(email: params[:user][:email])
        if @customer.present?
          add_to_merchant_customer_and_referrer
        else
          params[:user][:password] = Toolbox::StringGen.generate_random_string(8)
          params[:user][:user_level] = 0
          @customer = User.create(api_v1_user_params)
          if @customer.errors.present?
            response = @customer.errors.full_messages
            status = 500
          else
            @customer.create_address(@address_params) if any_address_params_present?
            @customer.people.create(@person_params) if api_v1_person_params[:full_name].present?
            @customer.user_lists.create(@user_list_params) if api_v1_user_list_params[:list_id].present?
            add_to_merchant_customer_and_referrer
            re = @customer.add_token_for_user(@user_params[:card_token], false) if @user_params[:card_token].present?
            unless re.first
              status = 500
              response = "Customer has been added but we are unable to add the customer's card"
              response += re.third ? ' because: ' + re.third : '.'
            end
          end
        end
      end
    rescue ActiveRecord::RecordNotUnique => e
      status = 500
      msg = e.original_exception.message
      response = "Customer's phone number is already in use." if msg.include?('index_users_on_phone_number')
      response = "Customer's email is already in use." if msg.include?('index_users_on_email')
    rescue StandardError => e
      status = 500
      response = 'Something went wrong on our end.'
    end

    render json: { response: response }, status: status
  end

  private

    def api_v1_user_params
      @user_params = params.require(:user)
                           .permit(:email, :password, :phone_number, :user_level, :card_name, :last4, :exp_month, :exp_year, :card_token, :card_type)
                           .tap do |u|
                              u[:card_name] = u[:card_name].present? ? u[:card_name] : nil
                              u[:last4] = u[:last4].present? ? u[:last4] : nil
                              u[:exp_month] = u[:exp_month].present? ? u[:exp_month] : nil
                              u[:exp_year] = u[:exp_year].present? ? u[:exp_year] : nil
                              u[:card_token] = u[:card_token].present? ? u[:card_token] : nil
                              u[:card_type] = u[:card_type].present? ? u[:card_type] : nil
                            end
    end

    def api_v1_address_params
      params.require(:user)
            .require(:address).permit(:street_address, :state_province, :city, :country, :postal_code)
            .tap do |u|
        u[:street_address] = u[:street_address].present? ? u[:street_address] : nil
        u[:state_province] = u[:state_province].present? ? u[:state_province] : nil
        u[:city] = u[:city].present? ? u[:city] : nil
        u[:country] = u[:country].present? ? u[:country] : nil
        u[:postal_code] = u[:postal_code].present? ? u[:postal_code] : nil
      end
    end

    def api_v1_person_params
      @person_params = params.require(:user).require(:person).permit(:full_name)
    end

    def api_v1_user_list_params
      @user_list_params = params.require(:user).require(:user_list).permit(:list_id)
    end

    def any_address_params_present?
      @address_params = api_v1_address_params
      @address_params[:street_address].present? || @address_params[:state_province].present? || @address_params[:city].present? || @address_params[:country].present? || @address_params[:postal_code].present?
    end

    def add_to_merchant_customer_and_referrer
      MerchantCustomer.add_or_update_merchant_customer([current_user.id, User.get_platform_acct_obj.id], @customer.id)
      Referrer.save_referrer_with_uid(current_user.relay_uid, @customer.id)
    end

end
