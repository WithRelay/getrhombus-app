# frozen_string_literal: true

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

IDS_TO_EXCLUDE = [2, 29_919, 29_920, 29_921, 29_922, 29_923, 29_924, 29_925, 29_926, 29_927, 29_928, 13_118, 12_570, 12_569, 29_544,
                  21_401, 26_633, 13_117, 29_803, 29_802, 48_186, 48_954, 49_052, 48_948, 48_946, 47_944, 47_943, 47_942, 47_941, 21_405, 30_079, 22_480, 13_119,
                  50_805, 50_777, 50_776, 50_775, 48_950, 48_949, 48_951, 48_952, 48_953, 51_385, 51_753, 51_754, 56_848, 51_725, 51_726, 51_723, 51_724, 22_606, 48_258,
                  13_116, 56_926, 56_927, 56_957, 56_958, 29_544, 29_860, 29_861, 57_468, 13_912, 58_332, 58_288, 58_287, 58_274, 58_273, 58_272, 58_315, 61_983, 61_982, 62_084,
                  123_811, 123_810, 123_809, 123_808, 123_807, 123_989, 123_990].freeze
