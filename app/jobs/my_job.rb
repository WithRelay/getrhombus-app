class MyJob
  def self.perform
    # if we get mysql has gone away errors
    # ActiveRecord::Base.clear_active_connections!
    # Do anything here
    puts "Email user to complete their profile"
  end
end