module UsersHelper
  def user_full_name
    current_user.first_name + ' ' + current_user.last_name
  end

  def login_user_type
    current_user.is_merchant? ? 'merchant' : 'customer'
  end

  def get_time_zone_lists
    ActiveSupport::TimeZone::MAPPING.map{ |z| [z.first, z.first] }.sort {|x,y| x[0] <=> y[0]}
  end

  def business_type_list
    ['Business', 'Nonprofit', 'Education', '[K12] Education [University & Colleges]', 'Individual']
  end

  def twilio_countries
    TextingService.twilio_list.keys.map do |k|
      [TextingService.twilio_list[k][:name], k]
    end
  end

  def rhombus_for
    ['Customer Support', 'Sales', 'Marketing', 'Payments']
  end

  def select_team_size
    ['1 - 5 employees', '6 - 20 employees', '21 - 50 employees', '51 - 100 employees',
    '101 - 200 employees', '201 - 500 employees', '501 - 1000 employees',
    '1001 - 3000 employees', '3001 - 5000 employees', '5000+ employees']
  end

  def stripe_standalone_cred
    current_user.stripe_creds.where(uid_type: 1)[0]
  end
end
