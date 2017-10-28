# using namespacing like thi is not best practice. This should be changed in the future.
$redis_merchant_status = Redis::Namespace.new($merchant_status_redis_namespace, :redis => Redis.new)
