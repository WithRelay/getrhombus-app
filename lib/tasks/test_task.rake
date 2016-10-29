
# run after all migrations to create alerts for users

desc "Test task"
task :test_task => :environment do
  
  User.all.each do |t|
    puts t.email
    puts '\n'
  end
end