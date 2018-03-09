module DeviseHelper
  def devise_error_messages!
    #return '' if resource.errors.blank?
    resource.errors.full_messages
=begin
    messages = resource.errors.full_messages.map { |msg| content_tag(:li, msg) }.join
    sentence = I18n.t('errors.messages.not_saved',
      count: resource.errors.count,
      resource: resource.class.model_name.human.downcase)

    html = <<-HTML
    <div class="alert alert-error alert-block">
      <button type="button" class="close" data-dismiss="alert"></button>
      <h4>#{sentence}</h4>
      #{messages}
    </div>
    HTML

    html.html_safe
=end
  end

  # Returns JSON object with the current user id
  def get_current_user_info
    return {}.to_json if current_user.nil? || !current_user.is_merchant?
    {
      id: current_user.id,
      pubnub_publish_key: Rails.application.secrets.pubnub["publish_key"],
      pubnub_subscribe_key: Rails.application.secrets.pubnub["subscribe_key"],
      short_url: current_user.short_url,
      first_name: current_user.first_name || 'there',
      #num_of_chars: current_user.rn_type.present? ? 1500 : 150,   # remove when we migrate fully to twilio
      num_of_chars: current_user.rhombus_number.try(:type).present? ? 1500 : 150,   # remove when we migrate fully to twilio
      customer_contact_count: MerchantCustomer.where(merchant_id: current_user.id).count + MerchantContact.where(merchant_id: current_user.id).count,
      can_accept_payments: current_user.can_accept_payments?(true), # because account could be pending
      profile_image: User.check_profile_picture(current_user),
      #has_messenger: current_user.get_page_access_token && true,
      message_channel: "messaging_" + Rails.env + "_" + current_user.id.to_s,
    }.to_json
  end
end