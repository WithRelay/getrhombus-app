class BasePresenter < SimpleDelegator
  include Rails.application.routes.url_helpers
  include PrettyDate

  SYMBOL_TIMES = 1

  private_constant :SYMBOL_TIMES

  # might need to send user and template for partials in here
  def initialize(model, view, user)
    @model, @view, @user = model, view, user
    super(@model)
  end

  def h
    @view
  end

  def format_frequency_type
    @model.frequency_type.humanize.titleize
  end

  def to_user_date_time
    @model.date_time.in_time_zone(@user.time_zone) if @model.date_time.present?
  end

  def format_created_at
    @model.present? ? time_in_relative_form(@model.created_at, 'long_format') : "-"
  end

  def profile_image
    profile_pic = User.check_profile_picture(@model.user)
    if profile_pic[:type] == "image"
          html = h.image_tag(profile_pic[:value], class: 'table-profile-picture', width: 24)
          html = h.image_tag(profile_pic[:value], class: 'campaigns table-profile-picture', width: 24) if @model.class == Hashtag
    elsif profile_pic[:type] == "color"
      class_name_value = "table-profile-picture radius-color-#{profile_pic[:value]}"
      class_name = ['Reminder', 'Transaction'].include?(@model.class.to_s) ? class_name_value : "campaigns #{class_name_value}"
      html = ("<div class='"+class_name+"'></div>").html_safe
    end
    html
  end

  def date_in_word
    @model.created_at.strftime('%B %d, %Y')
  end

  def get_plan_intervals
    { "Weekly" => "week_1", "Bi-weekly" => 'week_2',
      "Monthly" => "month_1", "Every 3 months" => 'month_3',
      'Every 6 months' => 'month_6', 'Yearly' => 'year_1' }
  end

  def average_transaction
    customer_id = @model.class == MerchantCustomer ? @model.customer_id : @model.id
    user_average_transaction = Transaction.user_average_transaction_with_merchant(customer_id, @user.id)
    user_average_transaction != 0 ? "$ " + user_average_transaction.to_s : show_empty_symbol
  end

  def total_transaction
    customer_id = @model.class == MerchantCustomer ? @model.customer_id : @model.id
    user_total_transaction = Transaction.user_total_transaction_with_merchant(customer_id, @user.id)
    user_total_transaction != 0 ? "$ " + user_total_transaction.to_s : show_empty_symbol
  end

  def format_customer_name
    customer_id = @model.class == MerchantCustomer ? @model.customer_id : @model.id
    User.get_conversation_display_name(customer_id, 'user')
  end

  def first_visit_format_created_at
    txn = first_transaction
    txn.present? ? time_in_relative_form(txn.created_at, 'long_format') : '-'
  end

  def last_visit_format_created_at
    txn = last_transaction
    txn.present? ? time_in_relative_form(txn.created_at, 'long_format') : '-'
  end


  private

  def show_empty_symbol
    ('-' * SYMBOL_TIMES)
  end

  # includes all transaction types
  # capture, refunds, reloads and subscriptions
  def last_transaction
    Transaction.where(user_id: @model.customer_id, team_id: @model.merchant_id).last
  end

  def first_transaction
    Transaction.where(user_id: @model.customer_id, team_id: @model.merchant_id).first
  end

end
