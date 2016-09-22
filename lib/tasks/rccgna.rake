
desc "rccg NA notifications"
task :rccg_na => :environment do

  require 'uri' 
  
  def send_message(from, to, msg)
    api_key: '<redacted_api_key>'
    api_secret: '<redacted_api_secret>'
    # encode the nexmo uri
    uri = URI.encode_www_form([["api_key",api_key], ["api_secret", api_secret], ["from", from], ["to", to], ["text", msg]]) 
    response = HTTParty.post('https://rest.nexmo.com/sms/json?'+ uri, :headers => {"Content-Type" => "application/x-www-form-urlencoded"} )
    if response.code == 200 and response["messages"].first["status"] == "0"   
      puts "sent to =>  #{response['messages'].first['to']}"
    else      
      puts "not sent to =>  #{response['messages'].first['to']}"
    end
  end

  rhombus_numbers = [ "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>",
                      "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>"] 
  
  other_numbers = ['<redacted_phone_number>', '<redacted_phone_number>', '<redacted_phone_number>', '<redacted_phone_number>', '<redacted_phone_number>', '<redacted_phone_number>', '<redacted_phone_number>', '<redacted_phone_number>']

  sent_ary = []

  rhombus_numbers.each do |r|    
    sql = ActiveRecord::Base.send(:sanitize_sql_array, 
        ["SELECT #{r} as rhombus_number, t1.phone FROM 
          ( select messages.from as phone from messages where messages.to = ?
            union
            select messages.to as phone from messages where messages.from = ?
          ) t1
          inner join users on t1.phone = users.phone_number", r, r])

    results = Message.connection.execute(sql)
    results.each do |r|
      unless sent_ary.include? r[1]
        send_message(r[0], r[1], "Attending or streaming the RCCG NA 2016 Convention? Send your offering and pledges by texting the amount and description to <redacted_phone_number>. Ex: $20 Offering. -- Powered by Rhombus")
        sent_ary.push(r[1])
      end
    end
  end
  puts "doneeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"

  other_numbers.each do |r|    
    sql = ActiveRecord::Base.send(:sanitize_sql_array, 
        ["SELECT #{r} as rhombus_number, t1.phone FROM 
          ( select messages.from as phone from messages where messages.to = ?
            union
            select messages.to as phone from messages where messages.from = ?
          ) t1
          inner join users on t1.phone = users.phone_number", r, r])

    results = Message.connection.execute(sql)
    results.each do |r|
      unless sent_ary.include? r[1]
        send_message("<redacted_phone_number>", r[1], "Attending or streaming the RCCG NA 2016 Convention? Send your offering and pledges by replying to this number with the amount and description. Ex: $20 Offering. -- Powered by Rhombus")
        sent_ary.push(r[1])
      end
    end
  end
  puts "doneeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
  

end


  