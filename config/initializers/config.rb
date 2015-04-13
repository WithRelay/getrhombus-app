# Reads config file
config_file = File.join(Rails.root,'config','config.yml')
raise "#{config_file} is missing!" unless File.exists? config_file
CONFIG = YAML.load(ERB.new(File.read(config_file)).result)[Rails.env].symbolize_keys

# Pubnub

$pubnub = Pubnub.new(
  :publish_key   => CONFIG[:services]['pubnub']['publish_key'],
  :subscribe_key => CONFIG[:services]['pubnub']['subscribe_key']
)
