class Api::V1::ReferrersController < API::V1::BaseController

=begin
  def invite_business
    begin
      status = 500
      @referrer = Referrer.new(referrer_params)
      if @referrer.save
        response = 'Business invitation created successfully'
        status = 200
      else
        response = 'Business invitation is not created'
      end
    rescue StandardError => e
      response = 'Something went wrong on our end.'
    end       
    render json: { response: response }, status: status
  end

  private
    def referrer_params
      params.require(:referrer).permit(:referrer_name, :referrer_email, :email, :phone_number, :country, :org_name)
    end
=end
end
