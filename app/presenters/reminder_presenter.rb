class ReminderPresenter < BasePresenter
  def reminder_change_status_link
    return 'Inactive' if @model.inactive?
    text = @model.paused? ? 'Unpause' : 'Pause'
    h.link_to(text, change_status_user_reminder_path(@user, @model), method: :put, class: 'actions-button cancel')
  end

  def get_channel
  	channel_hash = {"facebook_messenger" => "Messenger", "sms" => "SMS"}
  	channel_hash[@model.channel] 
  end

  def get_time
  	date_time = @model.date_time
  	ampm = date_time.hour >= 12 ? "PM" : "AM"
  	hour =  (date_time.hour == 12 || date_time.hour == 0) ? 12 : date_time.hour % 12 
  	minute = date_time.min.to_s
  	minute = minute.length < 2 ? minute.prepend("0") : minute  

  	return hour.to_s + ":" + minute + " " + ampm 
  end

end
