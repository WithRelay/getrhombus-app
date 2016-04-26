json.array!(@hashtags) do |hashtag|
  json.extract! hashtag, :id, :name, :amount, :response, :tag, :is_precedent, :not_payment_tag
  json.url hashtag_url(hashtag, format: :json)
end
