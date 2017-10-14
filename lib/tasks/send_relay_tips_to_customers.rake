
# run at some point after launch
desc "Send relay tips"
task :send_relay_tips => :environment do

  def send_relay_tips(data)
    data.each do |d|
      team = User.find_by(id: d.user_id_to)
      if team
        customer = User.find_by(phone_number: d.from)
        if customer
          uid = customer.id
          uid_type = 'user'
        else
          uid = nil
          uid_type = 'phone_number'
        end

        Conversation.find_or_create_conversation_for_message_and_send_publish(team, customer, uid_type, uid, Message.relay_tip1)
        Conversation.find_or_create_conversation_for_message_and_send_publish(team, customer, uid_type, uid, Message.relay_tip2)
      end
    end
  end

  
  # exclude platform for now
  sql = "SELECT messages.from, messages.user_id_to
          FROM messages
          INNER JOIN users ON users.id = messages.user_id_to
          where users.user_level = 1 and users.id != 1
          group by messages.from"


  data = Message.find_by_sql([sql])
  puts data.inspect
  send_relay_tips(data)
  

  sql = "SELECT messages.from, messages.user_id_to FROM messages
          INNER JOIN users ON users.id = messages.user_id_to
          where users.id = 1 and 
          messages.from not in 
            (
              SELECT messages.from
              FROM messages
              INNER JOIN users ON users.id = messages.user_id_to
              where users.user_level = 1 and users.id != 1 group by messages.from
            )
          group by messages.from"

  data = Message.find_by_sql([sql])
  puts data.inspect
  send_relay_tips(data) 
  
end
