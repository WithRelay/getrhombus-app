# Pubnub
pubnub_logger = Logger.new(File.join(Rails.root, 'log', 'pubnub.log'))
$pubnub = Pubnub.new(
  publish_key: Rails.application.secrets.pubnub['publish_key'],
  subscribe_key: Rails.application.secrets.pubnub['subscribe_key'],
  logger: pubnub_logger,
  ssl: true
)

GLOBAL_COLORS = [
  ['yellow', '#FFD966'], ['lilac', '#F8B5CC'], ['light-blue', '#B3D4FC'],
  ['light-green', '#97CB51'], ['purple', '#B5739D'], ['blue', '#3F51B5'],
  ['green', '#388E3C'], ['orange', '#FFC107'], ['dark-grey', '#607D8B'],
  ['red', '#FF5252']
].freeze

PAGINATION_PER_PAGE = 5

# in seconds, must be integer
SIGNUP_EMAIL_DELAY = 120
INCOMPLETE_SIGNUP_EMAIL_DELAY = 720

NUMBER_PRICE = 1

# Transactions before this date cannot be refunded
V1_5_LIVE_DATE = Time.now.utc
