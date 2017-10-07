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
    time_in_relative_form(@model.created_at, 'long_format')
  end

  def profile_image
    user = find_user

    profile_pic = User.check_profile_picture(user)
    puts profile_pic.inspect
    if profile_pic[:type] == "image"
      html = h.image_tag(profile_pic[:value], class: 'table-profile-picture', width: 24, alt: '')
      html = h.image_tag(profile_pic[:value], class: 'campaigns table-profile-picture', width: 24, alt: '') if need_campaign_class?
    elsif profile_pic[:type] == "color"
      class_name_value = "table-profile-picture radius-color-#{profile_pic[:value]}"
      class_name = ['Transaction'].include?(@model.class.to_s) ? class_name_value : "campaigns #{class_name_value}"
      html = ("<div class='"+ class_name + "'></div>").html_safe
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
    user_average_transaction = Transaction.user_average_transaction_with_merchant(@model.customer_id, @model.merchant_id)
    user_average_transaction != 0 ? "$ " + user_average_transaction.to_s : show_empty_symbol
  end

  def total_transaction
    user_total_transaction = Transaction.user_total_transaction_with_merchant(@model.customer_id, @model.merchant_id)
    user_total_transaction != 0 ? "$ " + user_total_transaction.to_s : show_empty_symbol
  end

  def format_customer_name
    User.get_conversation_display_name(@model.customer_id, 'user')
  end

  def customer_first_visit_formatted
    time_in_relative_form(@model.created_at, 'long_format')
  end

  def customer_last_visit_formatted
    time_in_relative_form(@model.updated_at, 'long_format')
  end

  def get_customer_location
    User.get_user_location(@model.customer_id, 'user', uid_obj=nil)
  end

  private

  def show_empty_symbol
    ('-' * SYMBOL_TIMES)
  end

  def find_user
    if @model.class == MerchantCustomer
      return @user.is_merchant? ? @model.customer : @model.merchant
    elsif  @model.class == MerchantContact
      return @user.is_merchant? ? nil : @model.merchant
    else
      @model.user
    end
  end

  def need_campaign_class?
    [Hashtag, MerchantCustomer].include?(@model.class)
  end

end
