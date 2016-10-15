# campaigns controller handles merchant's campaigns with different channels like
# MMS/SMS, email and facebook messeger
class CampaignsController < ApplicationController
  before_action :find_campaign, only: [ :update, :destroy, :change_status ]
  layout 'campaign'

  def index
    @campaigns = current_user.campaigns.includes(:images)
  end

  def new
    @campaign = Campaign.new
  end

  def create
    @campaign = current_user.campaigns.build(campaign_params)
    campaign_params[:list_ids].split(',').each { |list_id| @campaign.campaign_lists.build(list_id: list_id) }
    #save_campaign_images(@campaign)
    if @campaign.save
      flash[:notice] = 'Campaign Saved successfully'
    else
      flash[:error] = @campaign.errors.messages
    end
    redirect_to new_user_campaign_path
  end

  def edit
    @campaign = current_user.campaigns.includes(:images).find(params[:id])
    @lists = @campaign.lists
  end

  def update
    if @campaign.update_attributes(campaign_params)
      flash[:notice] = 'Campaign updated successfully'
    else
      flash[:error] = @campaign.errors.messages
    end
    redirect_to edit_user_campaign_path
  end

  def destroy
    if @campaign.destroy
      flash[:notice] = 'Campaign is being succesfully deleted'
    else
      flash[:error] = 'Sorry campaign could not delete please try again'
    end
    redirect_to user_campaigns_path
  end

  def change_status
    if @campaign.update_attributes(status: 2)
      flash[:notice] = 'Campaign paused'
    else
      flash[:notice] = 'Sorry campaign could not paused'
    end
    redirect_to user_campaigns_path
  end

  private

  def find_campaign
    @campaign = current_user.campaigns.find(params[:id])
  end

  def save_campaign_images(campaign)
    image_params[:avatar].each do |image|
      campaign.images.build(avatar: image)
    end if image_params[:avatar].present?
  end

  def campaign_params
    params.require(:campaign)
          .permit(:list_ids, :channel, :repeat_days, :date_time, :deliver_now, :frequency_type, :text)
          .tap do |c| # because they are enums
            c[:channel] = c[:channel].to_i
            c[:frequency_type] = c[:frequency_type].to_i
          end
  end

  def image_params
    params.require(:campaign).permit(avatar:[])
  end
end
