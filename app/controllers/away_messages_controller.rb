class AwayMessagesController < ApplicationController

  include DashboardNotification
  before_action :set_notifications

  def new
    @away_message = current_user.away_messages.build
  end

  def create
    @away_message = current_user.away_messages.build(away_message_params)
    if @away_message.save
      flash[:notice] = 'Away message saved successfully'
      redirect_to new_user_away_message_path(current_user)
    else
      flash[:error] = 'Away message could not save'
      render :new
    end
  end

  private

  def away_message_params
    params.require(:away_message).permit(:enabled, :response, :mon_ct, :mon_ot, :tue_ct, :wed_ct,
                                         :wed_ot, :thurs_ct, :thurs_ot, :fri_ct, :fri_ot, :sat_ct,
                                         :sun_ct, :sun_ot)
  end
end
