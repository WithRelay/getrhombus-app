class HashtagsController < ApplicationController
  before_action :set_hashtag, only: [:show, :edit, :update, :destroy]

  respond_to :html

  def index
    @hashtags = current_user.hashtags.paginate(:page => params[:page], :per_page => 25).order('updated_at DESC')
    respond_with(@hashtags)
  end

  def show
    respond_with(@hashtag)
  end

  def new
    @hashtag = Hashtag.new
    respond_with(@hashtag)
  end

  def edit
  end

  def create
    @hashtag = Hashtag.new(hashtag_params)
    @hashtag.user_id = current_user.id

    # create a plan and subscription if tag is recurring
    
    if @hashtag.save
      redirect_to user_hashtags_path       #respond_with(@hashtag)
    else
      respond_with(@hashtag)
    end
  end

  def update

    # create a new plan and subscription and delete old one on stripe if tag is recurring and key details change

    if @hashtag.update(hashtag_params)
      redirect_to user_hashtags_path
    end
    #@hashtag.update(hashtag_params)
    #respond_with(@hashtag)
  end

  def destroy
    if @hashtag.destroy
      redirect_to user_hashtags_path
    else
      respond_with(@hashtag) 
    end
    #@hashtag.destroy
    #respond_with(@hashtag) 
  end

  private
    def set_hashtag
      @hashtag = Hashtag.find(params[:id])
    end

    def hashtag_params
      params.require(:hashtag).permit(:amount, :response, :tag, :charge_amount, :tag_type, :interval, :interval_count,
        :enable_tweet, :description, images_attributes: [:avatar]).tap do |c|
                          c[:charge_amount] = c[:charge_amount].to_i
                          c[:tag_type] = c[:tag_type].to_i
                        end
    end
end
