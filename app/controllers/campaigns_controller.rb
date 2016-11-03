# campaigns controller handles merchant's campaigns with different channels like
# MMS/SMS, email and facebook messeger
class CampaignsController < ApplicationController
  before_action :find_campaign, only: [ :update, :destroy, :change_status ]
  before_action :check_campaign_status, only: [ :update, :destroy, :change_status]
  layout 'campaign'

  def index
    @campaigns = current_user.campaigns.includes(:images)
  end

  def new
    @campaign = current_user.campaigns.new
  end

  def create
    @campaign = current_user.campaigns.build(campaign_params)
    campaign_params[:list_ids].split(',').each { |list_id| @campaign.campaign_lists.build(list_id: list_id) }
    save_campaign_images(@campaign)
    if @campaign.save
      enqueue_jobs(@campaign)
      flash[:notice] = 'Campaign Saved successfully'
      redirect_to new_user_campaign_path
    else
      render :new
      flash[:error] = @campaign.errors.messages
    end
  end

  def edit
    @campaign = current_user.campaigns.includes(:images).find(params[:id])
    @lists_json = @campaign.lists.to_json
  end

  def update
    @campaign.campaign_lists.delete_all
    campaign_params[:list_ids].split(',').each { |list_id| @campaign.campaign_lists.build(list_id: list_id).save }
    save_campaign_images(@campaign)
    if @campaign.update_attributes(campaign_params)
      destroy_campaign_jobs
      enqueue_jobs(@campaign)
      flash[:notice] = 'Campaign updated successfully'
    else
      flash[:error] = @campaign.errors.messages
    end
    redirect_to edit_user_campaign_path
  end

  def destroy
    if @campaign.destroy
      destroy_campaign_jobs
      flash[:notice] = 'Campaign is being succesfully deleted'
    else
      flash[:error] = 'Sorry campaign could not delete please try again'
    end
    redirect_to user_campaigns_path
  end

  def change_status
    status = @campaign.active? ? 2 : 1
    if @campaign.update_attribute('status', status)
      change_campaign_job
      flash[:notice] = "Campaign #{@campaign.status}"
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

  def change_campaign_job
    date_today = Date.today.strftime("%Y-%m-%d")
    utc_date_time = @campaign.date_time.in_time_zone(@campaign.user.time_zone).utc
    today_campaign = utc_date_time.strftime("%Y-%m-%d") == date_today
    if @campaign.active? && today_campaign
      Resque.enqueue_at_with_queue('default', utc_date_time, ChannelJob, @campaign.id)
    else
      destroy_campaign_jobs
    end
  end

  def destroy_campaign_jobs
    Resque.remove_delayed_selection { |args| args[0] == @campaign.id }
  end

  def find_campaign
    @campaign = current_user.campaigns.find(params[:id])
  end

  def check_campaign_status
    if @campaign.inactive?
      flash[:alert] = 'sorry inactive campaign cannot be updated'
      redirect_to user_campaigns_path(current_user)
    end
  end

  def is_campaign_date_selected?(campaign)
    (campaign.one_time? && !campaign.deliver_now?)
  end

  def enqueue_jobs(campaign)
    utc_date_time = campaign.date_time.in_time_zone(campaign.user.time_zone).utc
    Resque.enqueue_at_with_queue('default', utc_date_time, ChannelJob, campaign.id) if is_campaign_date_selected?(campaign)
    CampaignJob.perform_now(campaign) if campaign.deliver_now
  end

  def save_campaign_images(campaign)
    image_params[:avatar].each do |image|
      campaign.images.build(avatar: image, uploaded_as: 1)
    end if (!campaign.sms? && image_params[:avatar].present?)
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
                                      c[:deliver_now]=='1' ? c[:deliver_now] = true : c[:deliver_now] = false
                                    end
  end

  def image_params
    params.require(:campaign).permit(avatar:[], image_id:[])
  end
end
