# campaigns controller handles merchant's campagins with different channels like
# MMS/SMS, email and facebook messeger
class CampaignsController < ApplicationController
  before_action :find_campaign, only: [ :update, :destroy, :change_status ]
  layout 'campaign'

  def index
    @campaigns = current_user.campaigns.includes(:images)
  end

  def new
    @campaign = current_user.campaigns.build
    @lists = current_user.lists
  end

  def create
    @campaign = current_user.campaigns.build(campaign_params)
    @campaign.campaign_lists.build(list_id: campaign_params[:list_id]) if campaign_params[:list_id].present?
    save_campaign_images(@campaign)
    if @campaign.save
      flash[:notice] = 'Campaign Saved successfully'
    else
      flash[:error] = @campaign.errors.mesages
    end
    redirect_to new_campaign_path
  end

  def edit
    @campaign = current_user.campaigns.includes(:images).find(params[:id])
    @lists = @campaign.lists
  end

  def update
    if @campaign.update_attributes(campaign_params)
      flash[:notice] = 'Campaign updated successfully'
    else
      flash[:error] = 'Sorry campaign could not update'
    end
    redirect_to edit_campaign_path(@campaign)
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
      flash[:notice] = 'Sorry campaign could not paused'
    end
    redirect_to campaigns_path
  end

  private

  def find_campaign
    @campaign = current_user.campaigns.find(params[:id])
  end

  def save_campaign_images(campaign)
    image_params[:image_id].each do |image_id|
      campaign.image_refs.build(image_id: image_id)
    end if image_params[:image_id].present?
    image_params[:avatar].each do |image|
      campaign.images.build(avatar: image)
    end if image_params[:avatar].present?
  end

  def campaign_params
    params.require(:campaign).permit(:list_id, :channel, :repeat_days, :date_time, :delivery_type,
                                     :frequency_type, :text).tap do |c|
                                      c[:channel] = c[:channel].to_i;
                                      c[:frequency_type] = c[:frequency_type].to_i;
                                      c[:delivery_type] = c[:delivery_type].to_i;
                                     end
  end

  def image_params
    params.require(:campaign).permit(image_id: [], avatar:[])
  end
end
