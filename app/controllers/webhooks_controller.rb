class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def stripe_events
    # should we return 500 if something goes wrong?
    #begin
      # Verify the event by fetching it from Stripe
      #event = Stripe::Event.retrieve(params[:id]) 
      #if params[:id] == event[:id]
        StripeEvent.process_event(params) 
      #end    
    #rescue StandardError => e
      # email platform
    #end
    render nothing: true
  end

  # set timezone for this request since we do duplicate payment check??
  def twilio_events

  end

  def facebook_events
    res = {}
    
    begin
      res = FacebookEvent.process_event(params)
    rescue StandardError => e
      # email platform
    end

    render json: res
  end
end