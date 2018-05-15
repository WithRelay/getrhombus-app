



desc "buy nexmo numbers"
task :buy_nexmo_numbers => :environment do
  u = User.find 2746
  
  u.numbers.delete_all

  country = "US"
  pattern = "1269"

  60.times do |i|
    
    res = TextingService.buy_number_nexmo(country, pattern)
    default = i == 0 ? 1 : 0

    if res.to_s.length > 5
      fn = "(" + res[1..3] + ") " + res[4..6] + "-" + res[7..10]
      u.numbers.create(number: res, friendly_name: fn, country: country, default: default)
    end

  end
  
  
end


