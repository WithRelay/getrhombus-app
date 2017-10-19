class NumbersController < ApplicationController

  def new; end

  def create
    re = current_user.buy_number(params['number'])
    if re
      flash[:notice] = 'Relay number added'
      redirect_to user_conversations_path
    else
      flash[:error] = 'We are unable to assign a Relay number. A member of our support team will contact you shortly.'
      ExceptionNotifier.notify_exception('', env: Rails.env, data: { message: "Unable to assign number for id #{current_user.id}" })
      redirect_to user_add_rhombus_number_path
    end
  end

end
