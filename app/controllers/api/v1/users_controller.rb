class Api::V1::UsersController < API::V1::BaseController

  # customer and contacts combined. Ex: for reminders or starting conversations
  def index
    q = params[:query].downcase
    # uid_type is fb_page, user, phone_number
    results = User.find_by_sql [
      "(select mc.customer_id as uid, 'user' as uid_type,
        coalesce(NULLIF(u.card_name, ''), u.email) as title, u.phone_number as description,
        CONCAT(uid, '-', 'user') AS unique_identifier
        from merchant_customers mc       
        inner join users u on mc.customer_id = u.id
        where mc.merchant_id = ? and
        (lower(u.card_name) like concat('%', ?, '%') or u.email like concat('%', ?, '%') or
        u.phone_number like concat('%', ?, '%'))) 

      union all

      (select uid, 'fb_page', name as title, 'Messenger Contact', 
      CONCAT(uid, '-', 'fb_page') AS unique_identifier
      from merchant_contacts
      inner join fb_creds on fb_creds.page_specific_id = merchant_contacts.uid
      where merchant_id = ? and uid_type = 'fb_page' and name <> '' and 
      (lower(name) like concat('%', ?, '%') or lower(email) like concat('%', ?, '%')))

      union all

      (select uid, 'phone_number', uid as title, 'SMS Contact' as description, 
      CONCAT(uid, '-', 'phone_number') AS unique_identifier
      from merchant_contacts
      where merchant_id = ? and uid_type = 'phone_number' and uid like concat('%', ?, '%'))",

      current_user.id, q, q, q, current_user.id, q, q, current_user.id, q]

    render json: { data: results }
  end

  def check_password
    res = current_user.valid_password?(params[:user][:current_password])
    render json: { valid: res }
  end

  def snapshot
    render json: User.get_user_snapshot(params[:uid], params[:uid_type], current_user.id)
  end

end
