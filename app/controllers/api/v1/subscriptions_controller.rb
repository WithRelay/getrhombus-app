class Api::V1::SubscriptionsController < API::V1::BaseController

  # create subscription from modal
  def create
    begin
      status = 500
      @subscription = Subscription.create(subscription_params)
      res = @subscription.create_subscription({ team: current_user })
      if res.first
        response = 'Subscription created successfully'
        status = 200
      else
        if @subscription.errors.messages.present?
          response = @subscription.errors.full_messages
          status = 409
        else
          response = (res.second == 'card_error') ? res.third : 'Something went wrong'
          status = 409
        end
        @subscription.destroy
      end
    rescue StandardError => e
      response = 'Something went wrong on our end.'
    end       
    render json: { response: response }, status: status 
  end

  private

  def subscription_params
    params.require(:subscription).permit(:quantity, :plan_id, :coupon_id, :merchant_customer_id)
  end

end
