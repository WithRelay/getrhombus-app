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

# in minutes, must be integer
SIGNUP_EMAIL_DELAY = 15  

# All in dollars. 04/01/17
SMS_PRICE_SENT = 0.015
SMS_PRICE_RECEIVED = 0.015
MMS_PRICE_SENT = 0.02
MMS_PRICE_RECEIVED = 0.04
NUMBER_PRICE = 1

# Transactions before this date cannot be refunded
V1_5_LIVE_DATE = Time.now.utc 
