



desc "buy twilio numbers"
task :buy_twilio_numbers => :environment do
  u = User.where(id: 2826)
  
  #### must remove config in twilio
  u.numbers.delete_all

  params = { query: '609', country: "US", type: "mobile" }
  
  res = u.buy_number(params, true, false)
  puts "Can't provision" unless res

  34.times do
    res = u.buy_number(params, false, false) 
    puts "Can't provision" unless res
  end
end


