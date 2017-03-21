class WelcomeEmailJob < ApplicationJob
  queue_as :default

  def self.perform(user)
    EmailingService.welcome_email(user)
  end

end
