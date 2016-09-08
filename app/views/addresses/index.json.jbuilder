json.array!(@addresses) do |address|
  json.extract! address, :id, :street_address, :city, :state_province, :country, :postal_code
  json.url address_url(address, format: :json)
end
