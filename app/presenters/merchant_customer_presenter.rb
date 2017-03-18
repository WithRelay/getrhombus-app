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
    txn = first_transaction
    txn.present? ? time_in_relative_form(txn.created_at, 'long_format') : '-'
  end

 def last_visit_format_created_at
    txn = last_transaction
    txn.present? ? time_in_relative_form(txn.created_at, 'long_format') : '-'
  end
  
  def average
  	transaction_avg = Transaction.where(user_id: @model.customer_id, team_id: @model.merchant_id, captured: true).average(:amount)
  	"$ #{'%.02f' % t = transaction_avg ? transaction_avg : 0 }"
  end

  def total
  	transaction_sum = Transaction.where(user_id: @model.customer_id, team_id: @model.merchant_id, captured: true).sum(:amount)
  	"$ #{'%.02f' % t = transaction_sum ? transaction_sum : 0}"
  end

private

  def last_transaction
    Transaction.where(user_id: @model.customer_id, team_id: @model.merchant_id).last
  end

  def first_transaction
    Transaction.where(user_id: @model.customer_id, team_id: @model.merchant_id).first
  end
end