# background job to process fibernetics event
class FiberneticsEventProcessJob < ApplicationJob
  queue_as :fibernetics_event

  def perform(params)
    FiberneticsEvent.new.process_event(params)
  end
end
