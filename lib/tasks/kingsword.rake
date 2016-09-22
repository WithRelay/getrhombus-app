
desc "Kingsword notifications"
task :kingsword => :environment do

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

  sql = ActiveRecord::Base.send(:sanitize_sql_array, 
      ["SELECT t1.phone FROM 
        ( select messages.from as phone from messages where messages.to: '<redacted_phone_number>'
          union
          select messages.to as phone from messages where messages.from: '<redacted_phone_number>'
        ) t1
        inner join users on t1.phone = users.phone_number"])

  results = Message.connection.execute(sql)
  count = 0
  results.each do |r|
    send_message("<redacted_phone_number>", r[0], "Kindly accept our sincere apologies for the RCCG NA related message you received. This was a system generated message sent to your number in error. Please note that no personal information was shared as this was an internally generated message. Thank you for being a valued user of Rhombus at Kingsword International Church -- Rhombus Team.")
    puts "#{count} r[0]"
    count = count + 1
  end
  puts "doneeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
  
end


  