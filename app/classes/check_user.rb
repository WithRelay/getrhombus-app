module CheckUser
  class RouteAuthentication

    def initialize(user)
      @user = user
    end

    def should_authenticate?
      return true if @user.is_customer?
      return merchant_details_present?  if @user.is_merchant?
    end

    def merchant_details_present?
      @user.get_saas_subscription.present? && @user.rhombus_number.present?
    end
  end
end
