class WeeklyActivitySummaryJob

  @queue = :weekly_activity_summary

  def self.perform
    
    User.where(user_level: 0).each do |user|
      
      time_in_zone = Time.current
      EmailingService.weekly_activity_summary(user)
  end

end