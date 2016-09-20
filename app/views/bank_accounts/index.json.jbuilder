json.array!(@bank_accounts) do |bank_account|
  json.extract! bank_account, :id, :stripe_bank_account_id, :country, :bank_name, :routing_number, :last4, :currency, :status, :default_for_currency
  json.url bank_account_url(bank_account, format: :json)
end
