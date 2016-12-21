class RemindersController < ApplicationController
  before_action :set_reminder, only: [ :edit, :update, :change_status ]

  def index
    @reminders = current_user.reminders
  end

  def new
    @reminder = current_user.reminders.build
  end

  def edit
  end

  def update
    if @reminder.update(reminder_params)
      flash[:notice] = 'Reminders updated'
      # @reminder.enqueue_jobs
      redirect_to user_reminders_path(current_user)
    else
      render :edit
      flash[:error] = @reminder.errors.full_messages
    end
  end

  def change_status
    status = @reminder.active? ? 2 : 1
    if @reminder.update_attribute('status', status)
      flash[:notice] = 'Reminder updated successfully'
    else
      flash[:error] = @reminder.errors.full_messages
    end
    redirect_to user_reminders_path(current_user)
  end

  private

  def set_reminder
    @reminder = current_user.reminders.find(params[:id])
  end

  def reminder_params
    # enums are define as integer but params are in string and rails is not converting string to integer
    params.require(:reminder).permit(:channel, :repeat_days, :date_time, :frequency_type, :text).tap do |c|
                                    c[:channel] = c[:channel].to_i; c[:frequency_type] = c[:frequency_type].to_i
                                    c[:date_time] = c[:date_time].present? ? c[:date_time].in_time_zone(current_user.time_zone) : nil
                                   end
  end
end
