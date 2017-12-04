class Api::V1::FongoCustomersController < Api::V1::BaseController

  def create
    begin
      api_cred = ApiCred.includes(:user).find_by(key: params[:key], secret: params[:secret])
      render json: { response: 'Invalid key/secret' }, status: :unauthorized and return unless api_cred      
      @merchant = api_cred.user

      status, error, response = 200, 'Something went wrong on our end.', 'User added'
      ActiveRecord::Base.transaction do
        @customer = User.find_by(email: params[:email])

        if @customer.present? 
          if @customer.is_customer?
            raise StandardError unless add_to_merchant_customer_and_referrer(false)
          end
        else
          params[:password] = params[:password] || Toolbox::StringGen.generate_random_string(8)
          params[:user_level] = 0

          @customer = User.new(api_v1_user_params)
          @customer.customer_source = { id: @merchant.id, method: 'added_skip_email', temp_password: params[:password] }
          @customer.save!

          raise StandardError unless merchant_customer = add_to_merchant_customer_and_referrer

          @customer.create_address!(@address_params) if any_address_params_present?
          @customer.people.create!(@person_params) if api_v1_person_params[:full_name].present?
        end
      end
    rescue ActiveRecord::RecordNotUnique => exception
      status = 500
      msg = exception.original_exception.message
      response = "Customer's phone number is already in use." if msg.include?('index_users_on_phone_number')
      response = "Customer's email is already in use." if msg.include?('index_users_on_email')
    rescue StandardError => exception
      ExceptionNotifier.notify_exception(exception, env: request.env, data: { message: "In v1 merchant_customers create", env: Rails.env })
      status = 500
      customer_errors = @customer.errors.full_messages
      response = customer_errors.present? ? customer_errors : error
    end

    render json: { response: response }, status: status
  end

  private

    def api_v1_user_params
      @user_params = params.permit(:email, :password, :phone1, :user_level, :phone_number)
                           .tap do |u|                              
                              u[:phone_number] = u[:phone1]
                              u.delete(:phone1)
                            end
    end

    def api_v1_address_params
      params.permit(:baddr1, :baddr2, :state, :city, :country, :zip, :street_address, :state_province, :postal_code)
            .tap do |u|
        u[:baddr1] = u[:baddr1].present? ? u[:baddr1] : ''
        u[:baddr2] = u[:baddr2].present? ? u[:baddr2] : ''

        u[:street_address] = (u[:baddr1] + " " + u[:baddr2]).squish
        u.delete(:baddr1)
        u.delete(:baddr2)

        u[:state_province] = u[:state].present? ? u[:state] : nil
        u.delete(:state)
        u[:city] = u[:city].present? ? u[:city] : nil
        u[:country] = u[:country].present? ? u[:country] : nil
        u[:postal_code] = u[:zip].present? ? u[:zip] : nil
        u.delete(:zip)
      end
    end

    def api_v1_person_params
      #@person_params = params.require(:user).require(:person).permit(:full_name)
      p = params.permit(:firstname, :lastname, :full_name)
      p[:full_name] = (p[:firstname] || '') + " " + (p[:lastname] || '').squish
      p.delete(:firstname)
      p.delete(:lastname)
      @person_params = p
    end

    def any_address_params_present?
      @address_params = api_v1_address_params
      @address_params[:street_address].present? || @address_params[:state_province].present? || @address_params[:city].present? || @address_params[:country].present? || @address_params[:postal_code].present?
    end

    def add_to_merchant_customer_and_referrer(with_referrer=true)
      Referrer.save_referrer_with_uid(@merchant.relay_uid, @customer.id) if with_referrer
      return false unless MerchantCustomer.add_or_update_merchant_customer(User.get_platform_acct_obj, @customer)
      # the status from this method is important
      MerchantCustomer.add_or_update_merchant_customer(@merchant, @customer)
    end


    #http://localhost:3000/v1/fongo/customers?email=<redacted_email>&password=qwerty12&baddr1=23 Test street&baddr2=ste 2&city=toronto&state=Ontario&zip=qwetty&firstname=test&lastname=testlastname&phone1=<redacted_phone_number>


    # 'name' => $TruncID, # not used
    # 'companyname' => $command->businessName, #not used
    # 'firstname' => $first_name, 
    # 'lastname' => $last_name, 
    # 'phone1' => $command->userCellNumber, 
    # 'baddr1' => $command->businessStreet1, 
    # 'baddr2' => $command->businessStreet2, 
    # 'city' => $command->businessCity, 
    # 'state' => $command->businessRegion, 
    # 'zip' => $command->businessPostCode, 
    # 'email' => $Smail, 
    # //'email' => $command->userEmail, 
    # 'login' => $TruncID, # not used
    # 'password' => $command->userPassword  # optional

end
