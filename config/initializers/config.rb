# Pubnub
pubnub_logger = Logger.new(File.join(Rails.root, 'log', 'pubnub.log'))
$pubnub = Pubnub.new(
  publish_key: Rails.application.secrets.pubnub["publish_key"],
  subscribe_key: Rails.application.secrets.pubnub["subscribe_key"],
  logger: pubnub_logger,
  ssl: true
)


