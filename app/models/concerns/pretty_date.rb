module PrettyDate
  #http://stackoverflow.com/questions/195740/how-do-you-do-relative-time-in-rails
  def super_short
    puts Time.current
    puts self
    a = (Time.current - self).to_i

    puts a.inspect
    puts "adasdasdas"

    #return 'adsdasdas'
    #debugger
    case a
      when 0..1 then '1s'
      when 2..59 then a.to_s + 's' 
      when 60..3599 then (a/60).to_i.to_s + 'm'
      when 3600..86399 then (a/60*60).to_i.to_s + 'h'
      when 86400..604799 then (a/(60*60*24)).to_i.to_s + 'd'
      else (a/(60*60*24*7)).to_i.to_s + 'w'
    end
  end
end

Time.send :include, PrettyDate