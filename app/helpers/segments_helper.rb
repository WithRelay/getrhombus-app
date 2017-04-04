module SegmentsHelper
  def segment_created_as(segment)
    segment_origin = { 'merchant' => 'Merchant', 'system' => 'Default' }
    segment_origin[segment.origin]
  end

  def number_of_users(segment)
    if segment.merchant?
      segment.get_users.count
    elsif (segment.name == 'Inactive Customers')
      binding.pry
      customers = eval(segment.segment)
      customers.present? ? customers : current_user.merchant_customers.pluck(:customer_id) +
                                       current_user.merchant_contacts.pluck(:uid)
    else
      eval(segment.segment)
    end
  end
end
