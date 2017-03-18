
# run after associate migration
desc "Set unread notification sent to true"
task :set_unread_notif_to_true => :environment do
	#NOOOOOOOOOOOOTTTTTTTTTTTTTTTTTTEEEEEEEEEEEEEEEEEEEEEE
	# this is now in converastion refs not in messages
	# set unread to false and set unread_notification_sent to true
  Message.all.update_all(unread_notification_sent: true)
end
