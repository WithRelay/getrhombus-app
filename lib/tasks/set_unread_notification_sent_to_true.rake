
# run after associate migration
desc "Set unread notification sent to true"
task :set_unread_notif_to_true => :environment do
  Message.all.update_all(unread_notification_sent: true)
end
