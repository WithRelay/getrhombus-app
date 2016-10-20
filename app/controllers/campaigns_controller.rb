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
    if @campaign.save
      save_campaign_images(@campaign)
      flash[:notice] = 'Campaign Saved successfully'
    else
      flash[:error] = @campaign.errors.messages
    end
    redirect_to new_user_campaign_path
  end

  def edit
    @campaign = current_user.campaigns.includes(:images).find(params[:id])
    @lists_json = @campaign.lists.to_json
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
    status = params[:new_status] == 'pause' ? 2 : 1
    if @campaign.update_attributes(status: status)
      flash[:notice] = 'Campaign paused'
    else
      flash[:notice] = 'Sorry campaign could not be paused'
    end
    redirect_to user_campaigns_path
  end

  def filter_campaign
    @campaigns = current_user.campaigns.where('status = ?', Campaign.statuses[params[:status]])
    render 'index'
  end

  private

  def find_campaign
    @campaign = current_user.campaigns.find(params[:id])
  end

  def save_campaign_images(campaign)
    # comment for attrachment for now later on it is needed
    # image_params[:avatar].each do |image|
    #   campaign.images.build(avatar: image)
    # end if image_params[:avatar].present?
    image_params[:image_id].each do |avatar_id|
      campaign.image_refs.build(image_id: avatar_id).save;
    end if image_params[:image_id].present?
  end

  def campaign_params
    # enums are define as integer but params are in string and rails is not converting string to integer
    params.require(:campaign).permit(:name, :list_ids, :channel, :repeat_days, :date_time, :deliver_now,
                                     :frequency_type, :text, :new_status).tap do |c|
                                      c[:channel] = c[:channel].to_i
                                      c[:frequency_type] = c[:frequency_type].to_i
                                    end
  end

  def image_params
    params.require(:campaign).permit(avatar:[], image_id:[])
  end
end
