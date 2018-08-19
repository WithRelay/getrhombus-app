



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

=begin
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
=end

  ary = []
  # toll free provisioning
  users = User.where(id: [14825])               # <<<<-------------------
  # 7889, 7890, 7891, 7892, 7893
  country = "CA"
  pattern = "1705"                              # <<<<-------------------
  size = 100
  type = "mobile-lvn" #"landline-toll-free"
  max_total = 190                               # <<<<-------------------
  #index = 2 

  users.each do |u|
    #u.numbers.delete_all
    total = u.numbers.count

    while (total < max_total && User.find(1).email == "<redacted_email>")
      numbers = TextingService.search_number_nexmo(country, pattern, size, type)

      if numbers
        numbers.each_with_index do |n, i|
          total = u.numbers.count
          if !(ary.include?(n["msisdn"].to_i)) && (total < max_total)
            puts n["msisdn"].inspect
            res = TextingService.buy_number_nexmo(n["country"], n["msisdn"])
            default = 0 #i == 0 ? 1 : 0

            if res
              fn = "(" + res[1..3] + ") " + res[4..6] + "-" + res[7..10]
              u.numbers.create(number: res, friendly_name: fn, country: n["country"], default: default, provider: 'nexmo', price: '210')
              TextingService.update_nexmo_number(n["country"], n["msisdn"], "tel", "<redacted_phone_number>")
            end
          end

        end
      end

      total = u.numbers.count
    end
    
  end


  ary = []
  # toll free provisioning
  users = User.where(id: [14825])               # <<<<-------------------
  # 7889, 7890, 7891, 7892, 7893
  country = "CA"
  pattern = "1905"                              # <<<<-------------------
  size = 100
  type = "mobile-lvn" #"landline-toll-free"
  max_total = 230                               # <<<<-------------------
  #index = 2 

  users.each do |u|
    #u.numbers.delete_all
    total = u.numbers.count

    while (total < max_total && User.find(1).email == "<redacted_email>")
      numbers = TextingService.search_number_nexmo(country, pattern, size, type)

      if numbers
        numbers.each_with_index do |n, i|
          total = u.numbers.count
          if !(ary.include?(n["msisdn"].to_i)) && (total < max_total)
            puts n["msisdn"].inspect
            res = TextingService.buy_number_nexmo(n["country"], n["msisdn"])
            default = 0 #i == 0 ? 1 : 0

            if res
              fn = "(" + res[1..3] + ") " + res[4..6] + "-" + res[7..10]
              u.numbers.create(number: res, friendly_name: fn, country: n["country"], default: default, provider: 'nexmo', price: '210')
              TextingService.update_nexmo_number(n["country"], n["msisdn"], "tel", "<redacted_phone_number>")
            end
          end

        end
      end

      total = u.numbers.count
    end
    
  end

  ary = []
  # toll free provisioning
  users = User.where(id: [14825])               # <<<<-------------------
  # 7889, 7890, 7891, 7892, 7893
  country = "CA"
  pattern = "1437"                              # <<<<-------------------
  size = 100
  type = "mobile-lvn" #"landline-toll-free"
  max_total = 280                               # <<<<-------------------
  #index = 2 

  users.each do |u|
    #u.numbers.delete_all
    total = u.numbers.count

    while (total < max_total && User.find(1).email == "<redacted_email>")
      numbers = TextingService.search_number_nexmo(country, pattern, size, type)

      if numbers
        numbers.each_with_index do |n, i|
          total = u.numbers.count
          if !(ary.include?(n["msisdn"].to_i)) && (total < max_total)
            puts n["msisdn"].inspect
            res = TextingService.buy_number_nexmo(n["country"], n["msisdn"])
            default = 0 #i == 0 ? 1 : 0

            if res
              fn = "(" + res[1..3] + ") " + res[4..6] + "-" + res[7..10]
              u.numbers.create(number: res, friendly_name: fn, country: n["country"], default: default, provider: 'nexmo', price: '210')
              TextingService.update_nexmo_number(n["country"], n["msisdn"], "tel", "<redacted_phone_number>")
            end
          end

        end
      end

      total = u.numbers.count
    end
    
  end











  ary = []
  # toll free provisioning
  users = User.where(id: [14821])               # <<<<-------------------
  # 7889, 7890, 7891, 7892, 7893
  country = "CA"
  pattern = "1819"                              # <<<<-------------------
  size = 100
  type = "mobile-lvn" #"landline-toll-free"
  max_total = 170                               # <<<<-------------------
  #index = 2 

  users.each do |u|
    #u.numbers.delete_all
    total = u.numbers.count

    while (total < max_total && User.find(1).email == "<redacted_email>")
      numbers = TextingService.search_number_nexmo(country, pattern, size, type)

      if numbers
        numbers.each_with_index do |n, i|
          total = u.numbers.count
          if !(ary.include?(n["msisdn"].to_i)) && (total < max_total)
            puts n["msisdn"].inspect
            res = TextingService.buy_number_nexmo(n["country"], n["msisdn"])
            default = 0 #i == 0 ? 1 : 0

            if res
              fn = "(" + res[1..3] + ") " + res[4..6] + "-" + res[7..10]
              u.numbers.create(number: res, friendly_name: fn, country: n["country"], default: default, provider: 'nexmo', price: '210')
              TextingService.update_nexmo_number(n["country"], n["msisdn"], "tel", "<redacted_phone_number>")
            end
          end

        end
      end

      total = u.numbers.count
    end
    
  end

  ary = []
  # toll free provisioning
  users = User.where(id: [14821])               # <<<<-------------------
  # 7889, 7890, 7891, 7892, 7893
  country = "CA"
  pattern = "1579"                              # <<<<-------------------
  size = 100
  type = "mobile-lvn" #"landline-toll-free"
  max_total = 220                               # <<<<-------------------
  #index = 2 

  users.each do |u|
    #u.numbers.delete_all
    total = u.numbers.count

    while (total < max_total && User.find(1).email == "<redacted_email>")
      numbers = TextingService.search_number_nexmo(country, pattern, size, type)

      if numbers
        numbers.each_with_index do |n, i|
          total = u.numbers.count
          if !(ary.include?(n["msisdn"].to_i)) && (total < max_total)
            puts n["msisdn"].inspect
            res = TextingService.buy_number_nexmo(n["country"], n["msisdn"])
            default = 0 #i == 0 ? 1 : 0

            if res
              fn = "(" + res[1..3] + ") " + res[4..6] + "-" + res[7..10]
              u.numbers.create(number: res, friendly_name: fn, country: n["country"], default: default, provider: 'nexmo', price: '210')
              TextingService.update_nexmo_number(n["country"], n["msisdn"], "tel", "<redacted_phone_number>")
            end
          end

        end
      end

      total = u.numbers.count
    end
    
  end


  ary = []
  # toll free provisioning
  users = User.where(id: [14821])               # <<<<-------------------
  # 7889, 7890, 7891, 7892, 7893
  country = "CA"
  pattern = "1343"                              # <<<<-------------------
  size = 100
  type = "mobile-lvn" #"landline-toll-free"
  max_total = 280                               # <<<<-------------------
  #index = 2 

  users.each do |u|
    #u.numbers.delete_all
    total = u.numbers.count

    while (total < max_total && User.find(1).email == "<redacted_email>")
      numbers = TextingService.search_number_nexmo(country, pattern, size, type)

      if numbers
        numbers.each_with_index do |n, i|
          total = u.numbers.count
          if !(ary.include?(n["msisdn"].to_i)) && (total < max_total)
            puts n["msisdn"].inspect
            res = TextingService.buy_number_nexmo(n["country"], n["msisdn"])
            default = 0 #i == 0 ? 1 : 0

            if res
              fn = "(" + res[1..3] + ") " + res[4..6] + "-" + res[7..10]
              u.numbers.create(number: res, friendly_name: fn, country: n["country"], default: default, provider: 'nexmo', price: '210')
              TextingService.update_nexmo_number(n["country"], n["msisdn"], "tel", "<redacted_phone_number>")
            end
          end

        end
      end

      total = u.numbers.count
    end
    
  end


end


