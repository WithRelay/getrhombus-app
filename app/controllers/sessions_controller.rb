class SessionsController < Devise::SessionsController

  include AdditionalUserActions

  def create
    set_captured_payment_session
    super
  end


end