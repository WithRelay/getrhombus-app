class IncompleteSignupJob < ApplicationJob
  queue_as :incomplete_signup

  def perform(user)
    begin
      Resque.logger.debug 'incomplete_signup job'
      EmailingService.incomplete_sign_up(user) unless user.get_saas_subscription
    rescue StandardError => exception
      ExceptionNotifier.notify_exception(exception, env: Rails.env, data: { message: "From IncompleteSignupJob",
                                                                            merchant: user })
    end
  end

end
