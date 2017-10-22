class SessionsController < Devise::SessionsController

  include AdditionalUserActions

  def create
    add_to_merchant_customer_and_referrer_and_fb_cred
    super
  end

  def destroy
    $redis_merchant_status.set(current_user.id.to_s, {}.to_json) if current_user.is_merchant?
    super
  end

  def set_merchant_status
  end
end