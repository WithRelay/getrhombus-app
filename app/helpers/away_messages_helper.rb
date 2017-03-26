module AwayMessages

  def time_for_ct_weeks
    hour = 1
    minute = 0
    final_hour_minute = ''
    ct_hour_minute = []
    while (final_hour_minute != '12:30 AM') do
      minute = minute + 30
      if minute == 60
        minute = 0
        hour = hour + 1
      end
      if minute == 0
        final_hour_minute = "#{hour}:#{minute}0 AM"
      else
        final_hour_minute = "#{hour}:#{minute} AM"
      end
      ct_hour_minute.push(final_hour_minute)
    end
  end
end
