class RemindersController < ApplicationController

  def index
    @reminders = current_user.reminders
  end

  def new
    @reminder = current_user.reminders.build
  end

  def edit
  end

  def change_status
  end
end
