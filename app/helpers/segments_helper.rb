module SegmentsHelper
  def segment_created_as(segment)
    segment_origin = { 'merchant' => 'Merchant', 'system' => 'Default' }
    segment_origin[segment.origin]
  end

  def number_of_users(segment)
    segment.get_mcs.total_entries
  end
end
