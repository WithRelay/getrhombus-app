class ChannelJob
  @queue = :send_email

  def self.perform(class_name = 'campaign')
    model = class_name.capitalize.constantize
    model.each { |obj|  "#{class_name}Service ".new(obj).set_background_jobs }
  end
end
