class CampaignsController < ApplicationController
  
  before_action :find_campaign, only: [:update]  
  load_and_authorize_resource

  include DashboardNotification

  before_action :set_notifications, except: [:update]
  before_action :check_campaign_status, only: [:update]

  def index
    @campaigns = current_user.campaigns#.is_active_or_paused
                             .paginate(per_page: 1, page: params[:page]).order(updated_at: :desc)
    @campaigns.present? ? render_requested_format(@campaigns) : render(:empty_campaign)
  end

  def new
    @campaign = current_user.campaigns.build
    @lists = current_user.lists.where(id: params[:list_id])
  end

  # creates a campaigns, campaign_lists, images if params available, associate inline image with campaign
  # NOTE: build method is being overidden in user model has_many :campaigns relationship
  def create
    @campaign = current_user.campaigns.build(campaign_params, image_params)
    if @campaign.save
      #@campaign.enqueue_jobs
      flash[:notice] = 'Campaign saved successfully'
      redirect_to user_campaigns_path(current_user)
    else
      flash[:error] = @campaign.errors.full_messages
      @lists = @campaign.campaign_lists.map { |a| current_user.lists.find(a.list_id) }
      render :new
    end
  end

  def edit
    @campaign = current_user.campaigns.includes(:images).find(params[:id])
    @lists = @campaign.lists
  end

  # note : update_attributes method is being overridden. see campaign model
  def update
    if @campaign.update_attributes(campaign_params, image_params)
      @campaign.change_campaign_job
      flash[:notice] = 'Campaign updated successfully'
    else
      flash[:error] = @campaign.errors.full_messages
    end
    redirect_to user_campaigns_path(current_user)
  end

  def filter_campaign
    @campaigns = current_user.campaigns.where('status = ?', Campaign.statuses[params[:status]])
                             .paginate(per_page: 1, page: params[:page]).order(updated_at: :desc)
                             
    if @campaigns.present?
      respond_to do |format|
        format.js { render partial: 'shared/index.js.erb', locals: { obj: @campaigns } }
        format.html { render(:index) }
      end
    else
      (params[:status] == 'active') ? render(:empty_campaign) : render(:empty_filter_campaign)
    end
  end

  private

  def find_campaign
    @campaign = current_user.campaigns.find(params[:id])
  end

  def check_campaign_status
    if @campaign.inactive?
      flash[:error] = 'You cannot update an inactive campaign'
      redirect_to user_campaigns_path(current_user)
    end
  end

  def campaign_params
    # enums are define as integer but params are in string and rails is not converting string to integer
    params.require(:campaign).permit(:name, :list_id, :channel, :repeat_days, :date_time, :deliver_now,
                         :frequency_type, :text, :subject).tap do |c|
                          c[:channel] = c[:channel].to_i
                          c[:frequency_type] = c[:frequency_type].to_i
                          c[:deliver_now] = c[:deliver_now] == '1' ? true : false

                          c[:repeat_days] = nil if c[:frequency_type] == 0
                          c[:date_time] = nil if c[:frequency_type] == 0 && c[:deliver_now]
                          c[:subject] = nil unless c[:channel] == 3
                          c[:date_time] = c[:date_time].present? ? c[:date_time].in_time_zone(current_user.time_zone) : nil
                        end
  end

  def image_params
    params.require(:campaign).permit(:avatar, image_id:[])
  end
end
