# Pubnub
pubnub_logger = Logger.new(File.join(Rails.root, 'log', 'pubnub.log'))
$pubnub = Pubnub.new(
  publish_key: Rails.application.secrets.pubnub["publish_key"],
  subscribe_key: Rails.application.secrets.pubnub["subscribe_key"],
  logger: pubnub_logger,
  ssl: true
)

COLORS = [
			['yellow','#FFD966'], ['lilac','#F8B5CC'], ['light-blue','#B3D4FC'],
		  	['light-green','#97CB51'], ['purple','#B5739D'], ['blue','#3F51B5'],
		  	['green','#388E3C'], ['orange','#FFC107'], ['dark-grey','#607D8B'],
		  	['red','#FF5252']
		  ].freeze

PAGINATION_PER_PAGE = 25
