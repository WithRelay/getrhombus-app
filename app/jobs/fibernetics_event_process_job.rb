# background job to process fibernetics event
class FiberneticsEventProcessJob < ApplicationJob
  def perform(params)
    FiberneticsEvent.new.process_event(params)
  end
end
