desc 'buy twilio numbers'
task buy_twilio_numbers2: :environment do
  ary = %w[]

  params = { query: '289', country: 'CA', type: 'local' }
  # size = 100
  # 1127
  max_total = 15
  numbers_ary = []
  total = numbers_ary.length

  u = User.find_by(email: '<redacted_email>'.downcase)
  puts u.inspect

  max_total.times do
    next unless total < max_total

    res = TextingService.search_number(params)
    puts "api return ->> #{res.inspect}"

    number = res[:number]
    next unless number.present? && ary.exclude?(number.gsub('+', '')) &&
                numbers_ary.exclude?(number.gsub('+', '')) && total < max_total

    puts 'about to buy'
    res = TextingService.buy_twilio_number(res)
    next unless res.present?

    puts res.inspect
    numbers_ary.push(res.first)
    total = numbers_ary.length
    u.numbers.create(number: res[0], friendly_name: res[1], number_type: params[:type], country: params[:country],
                     default: 0)
    puts "number #{total} !!!!!!!!!!!!!!!"
  end

  puts numbers_ary.length
  puts numbers_ary.inspect
end
# 266547, 267139, 267177
