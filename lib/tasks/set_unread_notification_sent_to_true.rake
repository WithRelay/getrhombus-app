
# TASK 9. Tested

# Note
# 1. run after running conversations rake task 
desc "Set unread notification sent to true"
task :set_unread_notif_to_true => :environment do
  ConversationRef.update_all(unread_notification_sent: true, unread: false)
end
