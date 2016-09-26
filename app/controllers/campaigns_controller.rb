# campaigns controller handles merchant's campagins with different channels like
# MMS/SMS, email and facebook messeger
class CampaignsController < ApplicationController

  def new
    @campaign = current_user.campaigns.build
    @lists = current_user.lists
  end

  def create
    @campaign = current_user.campaigns.build(campagin_params)
    @campaign.campaign_lists.build(Hash[*campagin_params.first])
    if @campaign.save
      flash[:notice] = 'Campaign Saved successfully'
    else
      flash[:error] = 'Sorry Campaign could not save please try again'
    end
    redirect_to new_campaign_path
  end

  def index
    @campaigns = current_user.campaigns
  end

  def edit
  end

  def update
  end

  def destroy
  end

  private

  def campagin_params
    params.require(:campaign).permit(:list_id, :channel, :repeat_days, :date, :time)
  end
end
