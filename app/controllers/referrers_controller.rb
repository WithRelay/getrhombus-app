# Referrers Controller
class ReferrersController < ApplicationController
  include DashboardNotification
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
    if @referrer.save
      flash[:notice] = 'Referral was successful'
    else
      flash[:error] = 'Referral failed'
    end
    ##### send email to referrer and referree here..
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
      r[:referrer_uid] = current_user.relay_uid if action_name == 'create'
    end
  end

end
