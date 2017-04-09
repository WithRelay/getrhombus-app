module CheckUser
  class RouteAuthentication

    def initialize(user)
      @user = user
    end

    def should_authenticate?
      return user_stripe_card_id if @user.is_customer?
      return merchant_details_present?  if @user.is_merchant?
    end

    def user_stripe_card_id
      @user.card_id.present?
    end 

    def merchant_details_present?
      @user.card_id.present? && @user.get_saas_subscription.present? && @user.rhombus_number.present?
    end
  end
end
