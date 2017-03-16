require "stripe"
Stripe.api_key = Rails.application.secrets.stripe["secret_key"]
STRIPE_REFUND_REASONS = ['fraudulent', 'duplicate', 'requested_by_customer'].freeze

