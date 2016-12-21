class RemindersController < ApplicationController

  def index
    @reminders = current_user.reminders
  end

  def new
    @reminder = current_user.reminders.build
  end

  def edit
    @reminder = current_user.reminders.find(params[:id])
  end

  def update
    @reminder = current_user.reminders.find_by_id(params[:id])
    if @reminder.update(reminder_params)
      flash[:notice] = 'Reminders updated'
      # @reminder.enqueue_jobs
      redirect_to user_reminders_path(current_user)
    else
      render :edit
      flash[:error] = @reminder.errors
    end
  end

  def change_status; end

  private
  def reminder_params
    # enums are define as integer but params are in string and rails is not converting string to integer
    params.require(:reminder).permit(:channel, :repeat_days, :date_time, :frequency_type, :text).tap do |c|
                                    c[:channel] = c[:channel].to_i; c[:frequency_type] = c[:frequency_type].to_i
                                    c[:date_time] = c[:date_time].present? ? c[:date_time].in_time_zone(current_user.time_zone) : nil
                                   end
  end
end
