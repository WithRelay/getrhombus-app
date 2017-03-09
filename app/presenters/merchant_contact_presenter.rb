class MerchantContactPresenter < BasePresenter

  def channel
    channel_list = { 'phone_number'=> 'SMS' }
    channel_list[@model.uid_type]
  end
end
