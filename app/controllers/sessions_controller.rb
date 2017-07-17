class SessionsController < Devise::SessionsController

  include AdditionalUserActions
  before_action :set_user_id, only: [:destroy]

  def create
    add_to_merchant_customer_and_referrer_and_fb_cred
    super
  end

  def destroy
    super do |user|
      $redis_merchant_status.set(@user_id, 'offline')
    end
  end

  private

  def set_user_id
    @user_id = current_user.id.to_s
  end

end