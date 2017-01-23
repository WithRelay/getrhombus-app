class WelcomeEmailJob

  @queue = :welcome_email

  def self.perform
    
    User.where(user_level: 0).each do |user|
      
      time_in_zone = Time.current

      if ((time_in_zone - user.created_at)/1.minute).to_i == 15
        EmailingService.welcome_email(user)
      end
    end
  end

end