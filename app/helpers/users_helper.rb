module UsersHelper
  def user_full_name
    current_user.first_name + ' ' + current_user.last_name
  end

  def login_user_type
    current_user.is_merchant? ? 'merchant' : 'customer'
  end
end
