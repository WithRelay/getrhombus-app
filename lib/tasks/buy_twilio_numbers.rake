



desc "buy twilio numbers"
task :buy_twilio_numbers => :environment do
  u = User.find 2746
  
  #### must remove config in twilio
  #<redacted_phone_number>
  u.numbers.delete_all

  params = { "area_code" => '269', "rn_country" => "US", "rn_type" => "local" }
  
  res = u.buy_number(params, true, false)
  puts "Can't provision" unless res

  59.times do
    res = u.buy_number(params, false, false) 
    puts "Can't provision" unless res
  end
end


