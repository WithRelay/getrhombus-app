module SegmentsHelper
  def segment_created_as(segment)
    segment_origin = { 'merchant' => 'Merchant', 'system' => 'Default' }
    segment_origin[segment.origin]
  end
end
