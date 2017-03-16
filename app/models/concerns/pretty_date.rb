module PrettyDate
  #http://stackoverflow.com/questions/195740/how-do-you-do-relative-time-in-rails
  def time_in_relative_form(time, format_params)
    a = (Time.current - time).abs.to_i
    short_format = { less_then_sec: '1s', sec: 's', min: 'm', hour: 'h', day: 'd', week: 'w', }
    medium_format = { less_then_sec: '1 sec', sec: 'sec', min: 'mins', hour: 'hrs', day: 'days', week: 'week'}
    long_format = { less_then_sec: '1 sec ago', sec: 'sec ago', min: 'minuntes ago', hour: 'hours ago', day: 'days ago', week: 'weeks ago'}
    
    format = eval(format_params)
    # binding.pry
    case a
      when 0..1 then format[:less_then_sec]
      when 2..59 then a.to_s +  format[:sec]
      when 60..3599 then (a/60).to_i.to_s + format[:min]
      when 3600..86399 then (a/(60*60)).to_i.to_s + format[:hour]
      when 86400..604799 then (a/(60*60*24)).to_i.to_s + format[:day]
      else (a/(60*60*24*7)).to_i.to_s + format[:week]
    end  
  end
end