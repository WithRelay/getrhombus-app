# campaigns controller handles merchant's campagins with different channels like
# MMS/SMS, email and facebook messeger
class CampaignsController < ApplicationController
  before_action :find_campaign, only: [ :update, :destroy, :change_status ]

  def index
    @campaigns = current_user.campaigns.includes(messages: [:images])
  end

  def new
    @campaign = current_user.campaigns.build
    message = @campaign.messages.build
    message.images.build
    @lists = current_user.lists
  end

  def create
    @campaign = current_user.campaigns.build(campaign_params)
    @campaign.campaign_lists.build(Hash[*campaign_params.first])
    if @campaign.save && save_message_images(@campaign.messages)
      flash[:notice] = 'Campaign Saved successfully'
    else
      flash[:error] = 'Sorry Campaign could not save please try again'
    end
    redirect_to new_campaign_path
  end

  def edit
    @campaign = current_user.campaigns.includes(messages: [:images]).find(params[:id])
    @lists = @campaign.lists
  end

  def update
    @campaign.update_attributes(campaign_params)
  end

  def destroy
    if @campaign.destroy
      flash[:notice] = 'Campaign is being succesfully deleted'
    else
      flash[:error] = 'Sorry campaign could not delete please try again'
    end
    redirect_to campaigns_path
  end

  def change_status
    if @campaign.update_attributes(status: 2)
      flash[:notice] = 'Campaign paused'
    else
      flash[:notice] = 'sorry campaign could not paused'
    end
    redirect_to campaigns_path
  end

  private

  def find_campaign
    @campaign = current_user.campaigns.find(params[:id])
  end

  def save_message_images(message)
    if image_params[:messages_attributes]["0"][:images_attributes].present?
      image_params[:messages_attributes]["0"][:images_attributes]["0"][:avatar].each do |image|
        message[0].images.build(avatar: image)
      end
      message[0].save
    end
  end

  def campaign_params
    params.require(:campaign).permit(:list_id, :channel, :repeat_days, :date_time, :delivery_type,
                                     :frequency_type, messages_attributes: [:text])
  end

  def image_params
    params.require(:campaign).permit(messages_attributes: [:text, images_attributes: [avatar: []]])
  end
end
