module UsersHelper
  def user_full_name
    current_user.first_name + ' ' + current_user.last_name
  end

  def login_user_type
    current_user.is_merchant? ? 'merchant' : 'customer'
  end

  def get_time_zone_lists
    ActiveSupport::TimeZone::MAPPING.map{ |zone| zone }
  end

  def business_type_list
    ['Business', 'Nonprofit', 'Education', '[K12] Education [University & Colleges]', 'Individual']
  end

  def rhombus_for
    %W(Customer Support Sales Marketing Payments)
  end

  def select_team_size
    ['1 - 5 employees', '6 - 20 employees', '21 - 50 employees', '51 - 100 employees',
    '101 - 200 employees', '201 - 500 employees', '501 - 1000 employees',
    '1001 - 3000 employees', '3001 - 5000 employees', '5000+ employees']
  end
end
