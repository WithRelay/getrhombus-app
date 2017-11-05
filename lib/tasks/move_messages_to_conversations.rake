
# TASK 8. Tested

# Note
# 1. run after migrations to create/rename the columns, since table need to be redone first
# 2. must run task 5 in setup_platform_stuff

desc "move messages to conversations"
task :move_messages_to_conversations => :environment do

  def update_conversation_resolution(team_id, conv_id, conv_ref_id, source, m)
    conv_res = ConversationResolution.where(conversation_id: conv_id, resolution: nil).last || ConversationResolution.new
    key = source == 'customer' ? :uid_conversation_ref_id : :merchant_conversation_ref_id
    conv_res.update_attributes!(key => conv_ref_id, merchant_id: team_id, conversation_id: conv_id, created_at: m.created_at, updated_at: m.updated_at)
  end

  ActiveRecord::Base.transaction do  
    orphaned_count = 0
    Message.find_each do |m|  
      puts "\n"
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

        c = Conversation.find_or_create_by!(merchant_id: m.user_id, uid: uid, uid_type: uid_type)
        c.update!(updated_at: m.updated_at, created_at: m.created_at)
        cr = ConversationRef.create!(textable_id: m.id, textable_type: 'Message', conversation_id: c.id, source: 1, created_at: m.created_at, updated_at: m.updated_at)
        update_conversation_resolution(u.id, c.id, cr.id, 'merchant', m)
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

          c = Conversation.find_or_create_by!(merchant_id: m.user_id_to, uid: uid, uid_type: uid_type)
          c.update!(updated_at: m.updated_at, created_at: m.created_at)
          cr = ConversationRef.create!(textable_id: m.id, textable_type: 'Message', conversation_id: c.id, source: 2, created_at: m.created_at, updated_at: m.updated_at)  
          update_conversation_resolution(u.id, c.id, cr.id, 'customer', m)
        else
          # else orphaned message  
          puts "this message is orphaned. id #{m.id} => #{m.text}"
          orphaned_count = orphaned_count + 1
          puts "#{orphaned_count} so far"
        end
      end

      puts "moving on... \n"
    end
    puts "#{orphaned_count} TOTAL"
  end

end