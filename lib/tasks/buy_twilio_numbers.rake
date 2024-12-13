# frozen_string_literal: true

desc 'buy twilio numbers'
task buy_twilio_numbers: :environment do
  u = User.find 267_131 # 266_548, 266_546, 266_547

  #### must remove config in twilio
  # <redacted_phone_number>
  # u.numbers.delete_all

  params = { 'area_code' => '647', 'rn_country' => 'CA', 'rn_type' => 'local' }

  # res = u.buy_number(params, true, false)
  # puts "Can't provision" unless res

  1.times do
    res = u.buy_number(params, false, false)
    puts res.inspect
    puts "Can't provision" unless res
  end
end
