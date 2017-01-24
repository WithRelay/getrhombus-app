class Api::V1::DemosController < API::V1::BaseController
  respond_to :json

  def create
    @demo = Demo.new(demo_params)
    EmailingService.send_demo_notifcation(@demo) if @demo.save
    render json: { response: 'Thank you! Your submission has been received!' }, status: 200
  end

  private

  def demo_params
   params.require(:demo).permit(:full_name, :company, :email, :phone, :employee_count)
  end
end
