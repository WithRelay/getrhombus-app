module AwayMessagesHelper

  def time_for_ct_weeks
    get_time_ct_ot('AM')
  end

  def time_for_ot_weeks
    get_time_ct_ot('PM')
  end

  def get_time_ct_ot(time_am_pm)
    hour = 1
    minute = 0
    final_hour_minute = ''
    ct_hour_minute = []
    while (final_hour_minute != "12:30 #{time_am_pm}") do
      minute = minute + 30
      if minute == 60
        minute = 0
        hour = hour + 1
      end
      final_hour_minute = minute == 0 ? "#{hour}:#{minute}0 #{time_am_pm}" : "#{hour}:#{minute} #{time_am_pm}"
      ct_hour_minute.push(final_hour_minute)
    end
    ct_hour_minute
  end
end
