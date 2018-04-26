class ApplicationJob < ActiveJob::Base
  before_perform do |job|
    ActiveRecord::Base.clear_active_connections!
  end

  rescue_from(ActiveRecord::RecordNotFound) do |exception|
    # Do something with the exception
    # send team email here
    puts exception.inspect
  end
end
