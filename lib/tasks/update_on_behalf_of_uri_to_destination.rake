
# TASK 13

# do this at some point so we can bring our data up to that with stripe

desc "Update all transactions with the old on_behalf_of_uri to destination account"
task :update_on_behalf_of_uri_to_destination_account => :environment do

  ActiveRecord::Base.transaction do
    users.each do |u|
      if u.first_name.present? || u.last_name.present? 
        puts "Update #{u.email}"
        person = Person.create!(first_name: u.first_name, last_name: u.last_name, role: '0', user_id: u.id)
        puts person.inspect
      end
      puts "Moving on \n"
    end
  end
 
 # also update all status from 1 to succeeded if status is a number
 # also update txn_available_at  #Time.parse(s).utc.to_i
end