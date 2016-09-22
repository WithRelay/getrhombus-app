require "stripe"
Stripe.api_key = Rails.application.secrets.stripe["secret_key"]