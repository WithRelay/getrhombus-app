class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token
  around_action :set_time_zone

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
    TwilioEvent.process_event(params, @merchant)
    render nothing: true
  end

  def nexmo_events
    NexmoEvent.process_event(params, @merchant)
    render nothing: true
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

  private 

    def set_time_zone(&block)
      if action_name == 'facebook_events'
        @merchant = User.first # placeholder....replace this
      elsif action_name == 'stripe_events'
        @merchant = User.first # placeholder....replace this
      elsif action_name == 'twilio_events'
        @merchant = User.find_by(rhombus_number: params[:To].gsub('+', ''))
      elsif action_name == 'nexmo_events'
        @merchant = User.find_by(rhombus_number: params[:to])
      end
      Time.use_zone(@merchant.time_zone, &block)
    end

end
