# sends email to campaign user list as scheduled
class CampaignJob < ActiveJob::Base
  queue_as :default

  def perform(campaign_id)
    campaign = Campaign.find_by_id(campaign_id)
    if campaign.present?
      email_list = campaign.lists.map{ |list| {email: list.user.email } if list.user.present? }
      campaign.images.each{|c| campaign.text.gsub!(c.avatar.url, "cid:#{c.avatar_file_name}")}
      image_params = campaign.images.map{ |image|  if image.avatar.present?
                                                    { type: image.avatar_content_type,
                                                      name: image.avatar_file_name,
                                                      content: Base64.encode64(open(image.avatar.url) { |image| image.read }) }
                                                    end
                                                    }
      message_hash = { html: campaign.text, to: email_list }
      email_campaign_hash = image_params.present? ? message_hash.merge({ images: image_params }) : message_hash
      EmailingService.send_email_campaign(email_campaign_hash)
    end
  end
end
