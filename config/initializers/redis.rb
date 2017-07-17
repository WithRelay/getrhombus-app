$redis_merchant_status = Redis::Namespace.new("relay-#{Rails.env}-merchant-status", :redis => Redis.new)
