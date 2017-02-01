class Api::V1::UsersController < API::V1::BaseController

  def add_customers
    begin
      status = 200
      
      if params[:format] == 'csv'
        # TODO
        #### review csv logic
        response = current_user.upload_customer_csv(params['csv'].tempfile)
      elsif params[:format] == 'json'
        u = User.where(email: params[:user][:email])
        if u.present?
          response = "User Added."
          #### TODO ####
          #### add user as merchant customer and add referrer - Referrer.save_referrer_with_id(current_user.id, u.id)
        else
          params[:user][:password] = Toolbox::StringGen.generate_random_string(8)
          params[:user][:user_level] = 0
          u = User.create(api_v1_user_params)
          if u.errors.present? # if serverside side error occurs it returns true 
            response = u.errors.full_messages
            status = 500
          else
            if params[:user][:street_address].present? || params[:user][:state_province].present? || params[:user][:city].present? || params[:user][:country].present? || params[:user][:postal_code].present?
              address = u.build_address(api_v1_address_params)
              address.save
            end
            u.people.create(api_v1_person_params)
            params[:user][:lists].split(',').each { |l| UserList.create(user_id: u.id, list_id:l) }
            #### TODO ####
            #### need to add customer's uri here
            #### then add user as merchant customer and add referrer - Referrer.save_referrer_with_id(current_user.id, u.id)
            response = 'User Added'
          end
        end
      end
    rescue ActiveRecord::RecordNotUnique => e
      response = e.original_exception.message
      status = 500
    rescue StandardError => e
      response = 'Something went wrong on our end.'
      status = 500
    end

    render json: { response: response }, status: status
  end

  private

    def api_v1_user_params
      params.require(:user).permit(:email, :password, :phone_number, :user_level, :card_name, :last4, :exp_month, :exp_year, 
                                    :card_token, :card_type).tap do |u|
                                                  u[:card_name] = u[:card_name].present? ? u[:card_name] : nil
                                                  u[:last4] = u[:last4].present? ? u[:last4] : nil
                                                  u[:exp_month] = u[:exp_month].present? ? u[:exp_month] : nil
                                                  u[:exp_year] = u[:exp_year].present? ? u[:exp_year] : nil
                                                  u[:card_token] = u[:card_token].present? ? u[:card_token] : nil
                                                  u[:card_type] = u[:card_type].present? ? u[:card_type] : nil
                                                end
    end

    def api_v1_address_params
      params.require(:user).permit(:street_address, :state_province, :city, :country, :postal_code).tap do |u|
                                                  u[:street_address] = u[:street_address].present? ? u[:street_address] : nil
                                                  u[:state_province] = u[:state_province].present? ? u[:state_province] : nil
                                                  u[:city] = u[:city].present? ? u[:city] : nil
                                                  u[:country] = u[:country].present? ? u[:country] : nil
                                                  u[:postal_code] = u[:postal_code].present? ? u[:postal_code] : nil
                                                end
    end

    def api_v1_person_params
      params.require(:user).permit(:first_name, :last_name).tap do |u|
        u[:first_name] = u[:first_name].present? ? u[:first_name] : nil
        u[:last_name] = u[:last_name].present? ? u[:last_name] : nil
      end
    end

end