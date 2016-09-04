class CardExpired

  @queue = :card_expired

  def self.perform
    
    # if we get mysql has gone away errors
    # ActiveRecord::Base.clear_active_connections!
    
    User.all.each do |user|
      # time.now.in_time_zone format year month is > card date then notify
      if false
        EmailingService.send_card_expired_email(user)
      end
    end
  end

end