class ReferrersController < ApplicationController
  before_action :set_referrer, only: [:show, :edit, :update, :destroy]

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

  def edit
  end

  def create
    @referrer = Referrer.new(referrer_params)
    @referrer.get_referrer_link
    @referrer.save
    ##### send email to referrer and referree here
    respond_with(@referrer)
  end

  def update
    @referrer.update(referrer_params)
    respond_with(@referrer)
  end

  def destroy
    @referrer.destroy
    respond_with(@referrer)
  end

  private
    def set_referrer
      @referrer = Referrer.find(params[:id])
    end

    def referrer_params
      params.require(:referrer).permit(:referrer_email, :email, :phone_number, :country, :referrer_name, :business_name)
    end
end
