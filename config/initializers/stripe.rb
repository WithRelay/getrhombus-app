require "stripe"
Stripe.api_key = Rails.application.secrets.stripe["secret_key"]
Stripe.api_version = '<redacted_phone_number>'
