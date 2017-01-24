class Api::V1::DemosController < API::V1::BaseController
  respond_to :html, :json

  def create
    @demo = Demo.new(demo_params)
    if @demo.save
      response = 'Thank you! Your submission has been received!'
      status = 200
    else
      response = 'Oops! Something went wrong while submitting the form'
      status = 500
    end
    render json: { response: response }, status: status
  end

  private

  def demo_params
     params.require(:demo).permit(:full_name, :company, :email, :phone, :employee_count)
  end
end
