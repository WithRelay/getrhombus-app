class MerchantCustomerPresenter < BasePresenter
  
  def profile_image
    profile_pic = User.check_profile_picture(@model.customer)
    if profile_pic[:type] == "image"
      html = h.image_tag(profile_pic[:value], class: 'campaigns table-profile-picture', width: 24)
    elsif profile_pic[:type] == "color"
      class_name = " campaigns table-profile-picture radius-color-#{profile_pic[:value]}"
      html = ("<div class='"+ class_name +"'></div>").html_safe
    end
    html
  end

  def first_visit_format_created_at
  	transactions = @transactions || customer_transactions
    if (transactions.present?)
      h.time_ago_in_words(transactions.first.created_at) + ' ago'
    else
      ' -- '
    end
  end

 def last_visit_format_created_at
  	transactions = @transactions || customer_transactions
    if (transactions.present?)
      h.time_ago_in_words(transactions.last.created_at) + ' ago'
    else
      '--'
    end

  end
  
  def average
  	transaction_avg = Transaction.where(user_id: @model.customer_id, team_id: @model.merchant_id).average(:amount)
  	"$ #{'%.02f' % t = transaction_avg ? transaction_avg : 0 }"
  end

  def total
  	transaction_sum = Transaction.where(user_id: @model.customer_id, team_id: @model.merchant_id).sum(:amount)
  	"$ #{'%.02f' % t = transaction_sum ? transaction_sum : 0}"
  end

  def customer_since_date
    @model.created_at.strftime('%m/%d/%Y')
  end

private

  def customer_transactions
    @transactions = Transaction.where(user_id: @model.customer_id, team_id: @model.merchant_id)
  end
end