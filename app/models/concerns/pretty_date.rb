module PrettyDate
  #http://stackoverflow.com/questions/195740/how-do-you-do-relative-time-in-rails

  def time_formats
    {
      short_format: { less_then_sec: '1s', sec: 's', min: 'm', hour: 'h', day: 'd', week: 'w' },
      short_ago_format: { less_then_sec: '1s ago', sec: 's ago', min: 'm ago', hour: 'h ago', day: 'd ago', week: 'w ago' },
      medium_format: { less_then_sec: '1 sec', sec: ' secs', min: ' min', min_p: ' mins', hour: ' hr', hour_p: ' hrs', day: ' day', day_p: ' days', week: ' week', week_p: ' weeks' },
      long_format: { less_then_sec: ' 1 sec ago', sec: ' secs ago', min: ' minute ago', min_p: ' minutes ago', hour: ' hour ago', hour_p: ' hours ago', day: ' day ago', day_p: ' days ago', week: ' week ago', week_p: ' weeks ago' }
    }
  end

  def has_plural_form?(format_str)
    ['medium_format','long_format'].include? format_str
  end

  def time_in_relative_form(time, format_str)
    a = (Time.current - time).abs.to_i
    
    format_type = time_formats[format_str.to_sym]
  
    case a
    when 0..1 
      format_type[:less_then_sec]
    when 2..59 
      a.to_s + format_type[:sec]
    when 60..3599 
      a = (a/60).to_i.to_s
      str = has_plural_form?(format_str) ? format_type[ a == "1" ? :min : :min_p ] : format_type[:min] 
      a + str
    when 3600..86399 
      a = (a/(60*60)).to_i.to_s 
      str = has_plural_form?(format_str) ? format_type[ a == "1" ? :hour : :hour_p ] : format_type[:hour] 
      a + str
    when 86400..604799 
      a = (a/(60*60*24)).to_i.to_s
      str = has_plural_form?(format_str) ? format_type[ a == "1" ? :day : :day_p ] : format_type[:day] 
      a + str
    else 
      a = (a/(60*60*24*7)).to_i.to_s
      str = has_plural_form?(format_str) ? format_type[ a == "1" ? :week : :week_p ] : format_type[:week] 
      a + str
    end 
  end

end