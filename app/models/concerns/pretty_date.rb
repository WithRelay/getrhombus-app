module PrettyDate
  #http://stackoverflow.com/questions/195740/how-do-you-do-relative-time-in-rails
  def time_in_relative_form(time, format_type)
    a = (Time.current - time).abs.to_i
    
    formats = {
      short_format: { less_then_sec: '1s', sec: 's', min: 'm', hour: 'h', day: 'd', week: 'w', },
      short_ago_format: { less_then_sec: '1s ago', sec: 's ago', min: 'm ago', hour: 'h ago', day: 'd ago', week: 'w ago', },
      medium_format: { less_then_sec: '1 sec', sec: ' secs', min: ' mins', hour: ' hrs', day: ' days', week: ' weeks'},
      long_format: { less_then_sec: ' 1 sec ago', sec: ' secs ago', min: ' minutes ago', hour: ' hours ago', day: ' days ago', week: ' weeks ago'}
    }

    format_type = formats[format_type.to_sym]
  
    case a
      when 0..1 then format_type[:less_then_sec]
      when 2..59 then a.to_s + format_type[:sec]
      when 60..3599 then (a/60).to_i.to_s + format_type[:min]
      when 3600..86399 then (a/(60*60)).to_i.to_s + format_type[:hour]
      when 86400..604799 then (a/(60*60*24)).to_i.to_s + format_type[:day]
      else (a/(60*60*24*7)).to_i.to_s + format_type[:week]
    end  
  end
end