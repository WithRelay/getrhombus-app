# Reads config file
config_file = File.join(Rails.root,'config','config.yml')
raise "#{config_file} is missing!" unless File.exists? config_file
CONFIG = YAML.load(ERB.new(File.read(config_file)).result)[Rails.env].symbolize_keys

pubnub_logger = Logger.new(File.join(Rails.root, 'log', 'pubnub.log'))

# Pubnub
$pubnub = Pubnub.new(
  :publish_key   => Rails.application.secrets.pubnub["publish_key"],
  :subscribe_key => Rails.application.secrets.pubnub["subscribe_key"],
  :logger => pubnub_logger
)
