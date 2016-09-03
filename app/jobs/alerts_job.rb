class AlertsJob
	 @queue = :alerts

	 def self.perform
    # if we get mysql has gone away errors
    # ActiveRecord::Base.clear_active_connections!
    
    # Add FB messages here
    results = Message.find_by_sql(
                "SELECT email, count(*) as unread_count 
                 FROM messages m
                 INNER JOIN users u 
                 on m.to = u.rhombus_number
                 WHERE m.unread = 1
                 GROUP BY m.to")

    results.each do |r|
      #if r["send_alert"]

      puts r['unread_count']
      #end


      
    end 

	 end



end