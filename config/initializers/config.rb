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
		  ]

M = 'blue'
#A = 'silver #bdc3c7, cloud #ecf0f1, carrot #e67e22, pumpkin #d35400, peter-river #3498db, orange #f39c12, green-sea #16a085, wisteria #8e44ad, sun-flower #f1c40f, midnight-blue #2c3e50'