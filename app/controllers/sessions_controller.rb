class SessionsController < Devise::SessionsController

  include AdditionalUserActions

  def create
    add_to_merchant_customer_and_referrer_and_fb_cred
    super
  end
end