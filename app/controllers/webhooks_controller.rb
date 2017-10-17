class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token
  around_action :set_time_zone

  def stripe_events
    begin
      # Verify the event by fetching it from Stripe
      #if PaymentService.retrieve_charge(type=='platform', ) params[:id] == event[:id]  
      type = (request.original_fullpath.include? 'platform') ? 'platform' : 'connect'
      StripeEvent.new.process_event(params, type)
      #end
    rescue StandardError => exception
      ExceptionNotifier.notify_exception(exception, env: Rails.env, data: { message: "In webhooks controller stripe_events" })
    end
    render nothing: true
  end

  # set timezone for this request since we do duplicate payment check??
  def twilio_events
    TwilioEvent.new.process_event(params, @merchant)
    render nothing: true
  end

  def nexmo_events
    NexmoEvent.new.process_event(params, @merchant)
    render nothing: true
  end

  def facebook_events
    res = {}
    begin
      res = FacebookEvent.new.process_event(params, current_page, @merchant)
    rescue StandardError => exception
      ExceptionNotifier.notify_exception(exception, env: Rails.env, data: { message: "In webhooks controller facebook_events" })
    end
    render json: res
  end

  def fibernetics_events
    begin
      FiberneticsEvent.new.process_event(params)
    rescue StandardError => exception
      ExceptionNotifier.notify_exception(exception, env: Rails.env, data: { message: "In webhooks controller fibernetics_events" })
    end
    render nothing: true
  end

  private

    def set_time_zone(&block)
      if action_name == 'facebook_events'
        @merchant = get_merchant if params['entry']
      elsif action_name == 'stripe_events' || action_name == 'fibernetics_events'
         @merchant = User.get_platform_acct_obj
      elsif action_name == 'twilio_events'
        @merchant = User.find_by(rhombus_number: params[:To].gsub('+', ''))
      elsif action_name == 'nexmo_events'
        @merchant = User.find_by(rhombus_number: params[:to])
      end

      ((render nothing: true) and return) if @merchant.blank? && params['hub.mode'].nil?
      params['hub.mode'].present? ? Time.use_zone(Rails.application.config.time_zone, &block) : Time.use_zone(@merchant.time_zone, &block)
    end

    def current_page
      required_params = params['entry'].try(:last)
      FbPage.find_by_page_id required_params['id'] if required_params
    end

    def get_merchant
      @merchant = current_page.user
    end

end
