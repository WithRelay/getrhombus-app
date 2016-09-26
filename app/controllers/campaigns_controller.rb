# campaigns controller handles merchant's campagins with different channels like
# MMS/SMS, email and facebook messeger
class CampaignsController < ApplicationController

  def new
    @campaign = current_user.campaigns.build
    message = @campaign.messages.build
    message.images.build
    @lists = current_user.lists
  end

  def create
    @campaign = current_user.campaigns.build(campaign_params)
    @campaign.campaign_lists.build(Hash[*campaign_params.first])
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

  def campaign_params
    params.require(:campaign).permit(:list_id, :channel, :repeat_days, :date_time, :delivery_type,
                                     :frequency_type, messages_attributes: [:text])
  end
end
