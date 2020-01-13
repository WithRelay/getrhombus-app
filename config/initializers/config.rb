# Pubnub
pubnub_logger = Logger.new(File.join(Rails.root, 'log', 'pubnub.log'))
$pubnub = Pubnub.new(
  publish_key: Rails.application.secrets.pubnub['publish_key'],
  subscribe_key: Rails.application.secrets.pubnub['subscribe_key'],
  logger: pubnub_logger,
  ssl: true
)

$merchant_status_redis_namespace = "relay-#{Rails.env}-merchant-status"

GLOBAL_COLORS = [
  ['yellow', '#FFD966'], ['lilac', '#F8B5CC'], ['light-blue', '#B3D4FC'],
  ['light-green', '#97CB51'], ['purple', '#B5739D'], ['blue', '#3F51B5'],
  ['green', '#388E3C'], ['orange', '#FFC107'], ['dark-grey', '#607D8B'],
  ['red', '#FF5252']
].freeze

PAGINATION_PER_PAGE = 15

IDS_TO_EXCLUDE = [2, 29919, 29920, 29921, 29922, 29923, 29924, 29925, 29926, 29927, 29928, 13118, 12570, 12569, 29544,
  21401, 26633, 13117, 29803, 29802, 48186,48954,49052,48948, 48946, 47944, 47943, 47942, 47941,21405,30079, 22480, 13119,
50805, 50777, 50776, 50775, 48950, 48949, 48951, 48952, 48953, 51385, 51753, 51754,56848, 51725, 51726, 51723, 51724, 22606,
13116, 56926, 56927, 56957, 56958, 29544, 29860, 29861].freeze