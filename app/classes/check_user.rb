module CheckUser
  class RouteAuthentication

    def initialize(user)
      @user = user
    end

    def should_authenticate?
      return user_card_token.present? if @user.is_customer?
      return merchant_details_present?  if @user.is_merchant?
    end

    def user_card_token
      @user.card_token
    end

    def merchant_details_present?
      user_card_token.present? && @user.get_saas_subscription.present? && @user.rhombus_number.present?
    end
  end
end
