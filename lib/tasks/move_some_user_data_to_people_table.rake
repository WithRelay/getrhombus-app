# run after migrations since we need the people table
# then run the migration below to remove the unwanted columns afterwards.

# remove columns
# will just delete first_name and last_name for customers, we dont need it
# we also dont really have addresses for them.
# but going forward customer address and person is in the respective tables
# 
=begin
  def change
    remove_column :users, :first_name
    remove_column :users, :last_name
  end

 # some cleanup
 # null or nothing  
    select * from users where user_level = 0 
    and last_name = '' # first_name = '' # is null

    select * from users where lower(card_name) = 'Visa'

    select * from users where card_name = card_type

    select * from users where user_level = 1 
    and last_name is null and first_name is not null

=end


desc "Move merchant person data to people table"
task :move_some_user_data_to_people_table => :environment do

  User.where(user_level: 1).each do |u|

    # move only merchants even if some user info is incomplete
    if (u.first_name.present? || u.last_name.present?)      
      Person.create(first_name: u.first_name, last_name: u.last_name, role: 'representative', user_id: u.id)
    end
  end
end