class DripCampaign

  @queue = :drip_campaigns

  def self.perform
    # if we get mysql has gone away errors
    # ActiveRecord::Base.clear_active_connections!
    #puts "dasdas"
    users = User.where(user_level: 0).first
    puts (Time.zone.now - users.created_at) <= 3.days.seconds
    
    #users.each do |user|
      
      #time_in_zone = 
     
      #puts time_in_zone
      #puts "\n"
      #puts (time_in_zone - user.created_at)

=begin  
      if (time_in_zone - user.created_at) <= 3.days.seconds.to_f
        send_three_day_email(user)
        puts "test"
      elsif (time_in_zone - user.created_at) <= 7.days.seconds.to_f
        send_proactive_support_email(user)
      elsif (time_in_zone - user.created_at) <= 10.days.seconds.to_f
        schedule_demo_email(user)
      end
=end
    #end

  end


  def send_founder_welcome_email(user)
    puts "send founder welcome email"
    puts user.email
  end


  def send_proactive_support_email(user)
    puts "send proactive support email"
    puts user.email
  end

  def schedule_demo_email(user)
    puts "send demo email"
    puts user.email
  end


end