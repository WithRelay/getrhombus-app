class Api::V1::SubscriptionsController < API::V1::BaseController

  def create
    begin
      status = 500
      res = customer_has_valid_card?
      if res.first
        @subscription = Subscription.new(subscription_params)
        res = @subscription.create_subscription({ team: current_user })
        if res.first
          response = 'Subscription created successfully'
          status = 200
        else
          if @subscription.errors.messages.present?
            response = @subscription.errors.full_messages
          else
            response = (res.second == 'card_error') ? res.third : 'Unable to create subscription.'
          end
          @subscription.destroy
        end
      else
        response = check_customer_card.second
      end
    rescue StandardError => e
      response = 'Something went wrong on our end.'
    end       
    render json: { response: response }, status: status
  end

  def update
    begin
      status = 500
      @subscription = Subscription.find params[:id]
      coupon = Coupon.find_by(name: params[:subscription][:coupon])
      if coupon && @subscription.update_subscription(current_user, coupon.stripe_coupon_id)
        response = 'Coupon updated successfully'
        status = 200
      else
        response = (coupon.nil?) ? 'Invalid Discount code' : 'We couldn\'t change discount'
      end      
    rescue StandardError => e
      response = 'Something went wrong on our end.'
    end
    render json: { response: response }, status: status
  end

  def destroy
    begin
      status = 500
      @subscription = Subscription.find params[:id]
      if @subscription.cancel_subscription(current_user)
        response = 'Your subscription has canceled'
        status = 200
      else
        response = 'We couldn\'t cancel your subscription'
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

  def customer_has_valid_card?
    MerchantCustomer.find_by(params[:merchant_customer_id]).customer.has_valid_card?
  end

end
