desc "remove duplicate message id in messages"
task :remove_duplicate_message_id_in_messages => :environment do  

  sql = "SET SQL_SAFE_UPDATES=0;
          UPDATE messages
            SET message_id = null 
            where message_id in (
              SELECT message_id
              FROM (select * from messages) as m
              GROUP BY message_id
              HAVING count(*) > 1);
        SET SQL_SAFE_UPDATES=1;"
  ActiveRecord::Base.connection.execute(sql)  
end
