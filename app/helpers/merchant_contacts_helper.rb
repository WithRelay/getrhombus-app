module MerchantContactsHelper
  def contact_or_customer
    params[:controller] == 'merchant_contacts' ? 'Contact' : 'Customer'
  end
end
