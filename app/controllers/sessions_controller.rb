class SessionsController < Devise::SessionsController

  include AdditionalUserActions

  def create
    add_or_update_user_referrer
    super
  end
end