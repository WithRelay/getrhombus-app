
# run after migrations to create/rename the columns, since table need to be redone first

desc "move messages to conversations"
task :move_messages_to_conversations => :environment do

  Message.all.each do |m|

    # Conversation must have merchant_id 
    # but can have different types of uids

    u = User.find_by(id: m.user_id)
    # if merchant
    if u && u.user_level == 1
      # find user
      if User.find_by(id: m.user_id_to)
        uid = m.user_id_to
        uid_type = 'User'
      else  # if no user, use phone number
        uid = m.to
        uid_type = 'PhoneNumber'
      end

      c = Conversation.find_by(merchant_id: m.user_id, uid: uid, uid_type: uid_type)
      if !c
        c = Conversation.create(merchant_id: m.user_id, uid: uid, uid_type: uid_type)
      end
      ConversationRef.create(textable_id: m.id, textable_type: 'Message', conversation_id: c.id)
      puts 'first block'
      puts m.user_id
        puts m.user_id_to
        puts c.to_json
        puts "\n\n"
    else
      
      u = User.find_by(id: m.user_id_to)
      # if merchant
      if u && u.user_level == 1
        # find user
        if User.find_by(id: m.user_id)
          uid = m.user_id
          uid_type = 'User'
        else  # if no user, use phone number
          uid = m.from
          uid_type = 'PhoneNumber'
        end


        c = Conversation.find_by(merchant_id: m.user_id_to, uid: uid, uid_type: uid_type)
        if !c
          c = Conversation.create(merchant_id: m.user_id_to, uid: uid, uid_type: uid_type)
        end
        puts 'second block'
        puts m.user_id_to
        puts m.user_id
        puts c.to_json
        puts "\n\n"
        ConversationRef.create(textable_id: m.id, textable_type: 'Message', conversation_id: c.id)  
      end

      # else orphaned message
    end
  end

end