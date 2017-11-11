# Referrers Controller
class ReferrersController < ApplicationController
  include DashboardNotification
  include Transactionable
  
  before_action :set_notifications, only: [:new]
  before_action :set_referrer, only: %i[show edit update destroy]

  respond_to :html, :json

  def index
    @referrers = Referrer.all
    respond_with(@referrers)
  end

  def show
    respond_with(@referrer)
  end

  def new
    @referrer = Referrer.new
    respond_with(@referrer)
  end

  def create    
    @referrer = Referrer.new(referrer_params)
    if User.exists?(email: @referrer.email)
      flash[:error] = 'The referred email already exists.'
    else
      if @referrer.save
        flash[:notice] = 'Referral was successful'
        EmailingService.referral_bonus_email(@referrer.email, 'there', current_user.first_name, User.profile_url_only(current_user))
      else
        flash[:error] = 'Referral failed'
      end
    end

    redirect_to user_refer_business_path
  end

  def update
    @referrer.update(referrer_params)
    respond_with(@referrer)
  end

  def destroy
    @referrer.destroy
    respond_with(@referrer)
  end

  def homepage_referrer
    @referrer = Referrer.create(referrer_params)
    render json: @referrer
  end

  private

  def set_referrer
    @referrer = Referrer.find(params[:id])
  end

  def referrer_params
    params.require(:referrer).permit(:referrer_email, :email, :phone_number, :country, :referrer_name, :org_name,
                                        :ip, :city, :region, :postal, :referrer_uid).tap do |r|
      if action_name == 'create'
        current_user.update_column(relay_uid: generate_uid) if current_user.relay_uid.blank?
        r[:referrer_uid] = current_user.relay_uid
      end
    end
  end

end
