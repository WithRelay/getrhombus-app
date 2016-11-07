
# run after all migrations 

=begin
  Then do this  
   def change
    remove_column :transactions, :receipt_sent_at   # txns now uses this class to track when receipts were sent
  end
=end

# This should run after all modifications to transactions table
# Since we shrink transactions across 3 rows into 1...we only want to run this after
# the shrinking is done

desc "Move receipt sent at"
task :move_receipt_sent_at_to_notifications_log => :environment do
  
  Transaction.all.each do |t|
    time = t.receipt_sent_at
    t.notification_logs.create(created_at: time, updated_at: time, notify_type: 'new_transaction', reason: 'receipt', channel: 'Message')
    t.notification_logs.create(created_at: time, updated_at: time, notify_type: 'new_transaction', reason: 'receipt', channel: 'Email')
  end

end