class MerchantContactPresenter < BasePresenter

  def channel
    channel_list = { 'phone_number'=> 'SMS' }
    channel_list[@model.uid_type]
  end

  def contact_details
    User.get_user_snapshot(@model.uid, @model.uid_type, @user.id, @model)
  end

end
