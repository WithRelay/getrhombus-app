



desc "buy nexmo numbers"
task :buy_nexmo_numbers => :environment do
  
=begin
  u = User.find 2746
  
  u.numbers.delete_all

  country = "US"
  pattern = "1269"

  60.times do |i|
    
    res = TextingService.search_and_buy_number_nexmo(country, pattern)
    default = i == 0 ? 1 : 0

    if res.to_s.length > 5
      fn = "(" + res[1..3] + ") " + res[4..6] + "-" + res[7..10]
      u.numbers.create(number: res, friendly_name: fn, country: country, default: default)
    end

  end
=end

  ary = [
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>,
    <redacted_phone_number>
  ]


  # toll free provisioning
  users = User.where(id: [13098])
  # 7889, 7890, 7891, 7892, 7893
  country = "US"
  pattern = ""
  size = 45
  type = "landline-toll-free"

  users.each do |u|
    u.numbers.delete_all
    numbers = TextingService.search_number_nexmo(country, pattern, size, type)
    if numbers
      numbers.each_with_index do |n, i|
        if !(ary.include?(n.to_i)) && u.numbers.count < 101

          res = TextingService.buy_number_nexmo(n["country"], n["msisdn"])
          default = i == 0 ? 1 : 0

          if res
            fn = "(" + res[1..3] + ") " + res[4..6] + "-" + res[7..10]
            u.numbers.create(number: res, friendly_name: fn, country: n["country"], default: default, provider: 'nexmo', price: '210')
            #TextingService.update_nexmo_number(n["country"], n["msisdn"], "tel", "<redacted_phone_number>")
          end
        end

      end
    end
  end

end


