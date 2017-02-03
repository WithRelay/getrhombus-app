# campaigns controller handles merchant's campaigns with different channels like
# MMS/SMS, email and facebook messeger
class CampaignsController < ApplicationController
  before_action :find_campaign, only: [ :update, :destroy, :change_status ]
  before_action :check_campaign_status, only: [ :update, :destroy, :change_status]

  # @campaigns contains array of campaign of the associated users
  def index
    @campaigns = current_user.campaigns
    render 'empty_campaign' unless @campaigns.present?
  end

  # initializing campaign as association way using build method.
  def new
    @campaign = current_user.campaigns.build
  end

  # creates a campaigns, campaign_lists, images if params available, associate inline image with campaign
  # NOTE: build method is being overide please go through user model has_many :campaigns relationship
  def create
    @campaign = current_user.campaigns.build(campaign_params, image_params)
    if @campaign.save
      @campaign.enqueue_jobs # enque jobs if there is send now checked or one time is checked
      flash[:notice] = 'Campaign Saved successfully'
      redirect_to edit_user_campaign_path(current_user, @campaign)
    else
      flash[:error] = @campaign.errors.full_messages
      @lists = @campaign.campaign_lists.map{|a| current_user.lists.find(a.list_id)}
      render :new
    end
  end

  def edit
    @campaign = current_user.campaigns.includes(:images).find(params[:id])
    @lists = @campaign.lists
  end

  # note : update_attributes method is being overide please go through campaign model
  def update
    if @campaign.update_attributes(campaign_params, image_params)
      @campaign.change_campaign_job
      flash[:notice] = 'Campaign updated successfully'
    else
      flash[:error] = @campaign.errors.full_messages
    end
    redirect_to edit_user_campaign_path
  end

  def filter_campaign
    @campaigns = current_user.campaigns.where('status = ?', Campaign.statuses[params[:status]])
    render 'index'
  end

  private

  def find_campaign
    @campaign = current_user.campaigns.find(params[:id])
  end

  def check_campaign_status
    if @campaign.inactive?
      flash[:alert] = 'sorry inactive campaign cannot be updated'
      redirect_to user_campaigns_path(current_user)
    end
  end

  def campaign_params
    # enums are define as integer but params are in string and rails is not converting string to integer
    params.require(:campaign).permit(:name, :list_name, :channel, :repeat_days, :date_time, :deliver_now,
                         :frequency_type, :text, :new_status, :subject).tap do |c|
                          c[:channel] = c[:channel].to_i
                          c[:frequency_type] = c[:frequency_type].to_i
                          c[:deliver_now] = c[:deliver_now] == '1' ? true : false
                          c[:subject] = nil unless c[:channel] == 3
                          c[:date_time] = c[:date_time].present? ? c[:date_time].in_time_zone(current_user.time_zone) : nil
                        end
  end

  def image_params
    params.require(:campaign).permit(:avatar, image_id:[])
  end
end
