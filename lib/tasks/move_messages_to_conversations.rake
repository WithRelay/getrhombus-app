
# TASK 8

# Note
# 1. run after migrations to create/rename the columns, since table need to be redone first
# 2. must run task 5 in setup_platform_stuff

desc "move messages to conversations"
task :move_messages_to_conversations => :environment do

  def update_conversation_resolution(team_id, conv_id, conv_ref_id, source)
    conv_res = ConversationResolution.where(conversation_id: conv_id, resolution: nil).last || ConversationResolution.new
    key = source == 'customer' ? :uid_conversation_ref_id : :merchant_conversation_ref_id
    conv_res.update_attributes!(key => conv_ref_id, merchant_id: team_id, conversation_id: conv_id)
  end

  Message.in_batches.each do |messages|
    puts "Going to update #{messages.count} messages"
    ActiveRecord::Base.transaction do  
      messages.each do |m|
        # Conversation must have merchant_id but can have different types of uids

        u = User.find_by(id: m.user_id)
        # if merchant
        if u.try(:is_merchant?)
          # find user
          if User.find_by(id: m.user_id_to)
            uid = m.user_id_to
            uid_type = 'user'
          else  # if no user, use phone number
            uid = m.to
            uid_type = 'phone_number'
          end

          if c = Conversation.find_by(merchant_id: m.user_id, uid: uid, uid_type: uid_type)
          else
            c = Conversation.create!(merchant_id: m.user_id, uid: uid, uid_type: uid_type)
          end
          c.update_column(:updated_at, m.created_at)
          cr = ConversationRef.create!(textable_id: m.id, textable_type: 'Message', conversation_id: c.id, source: 1)
          update_conversation_resolution(u.id, c.id, cr.id, 'merchant')
        else
          
          u = User.find_by(id: m.user_id_to)
          # if merchant
          if u.try(:is_merchant?)
            # find user
            if User.find_by(id: m.user_id)
              uid = m.user_id
              uid_type = 'user'
            else  # if no user, use phone number
              uid = m.from
              uid_type = 'phone_number'
            end

            if c = Conversation.find_by(merchant_id: m.user_id_to, uid: uid, uid_type: uid_type)
            else
              c = Conversation.create!(merchant_id: m.user_id_to, uid: uid, uid_type: uid_type)
            end
            c.update_column(:updated_at, m.created_at)
            cr = ConversationRef.create!(textable_id: m.id, textable_type: 'Message', conversation_id: c.id, source: 2)  
            update_conversation_resolution(u.id, c.id, cr.id, 'customer')
          end

          # else orphaned message
        end

        puts "moving on... \n"
      end
    end
    sleep(2)
  end

end