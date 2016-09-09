json.array!(@referrers) do |referrer|
  json.extract! referrer, :id, :referrer_email, :email, :phone_number, :referrer_id, :referee_id, :country, :link, :referrer_name, :org_name
  json.url referrer_url(referrer, format: :json)
end
