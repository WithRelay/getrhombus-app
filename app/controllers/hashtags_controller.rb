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
    @images = []
    respond_with(@hashtag)
  end

  def edit
    @images = @hashtag.images.map { |i| { url: i.avatar.url, id: i.id, name: i.avatar_file_name } }
  end

  def create
    @hashtag = Hashtag.new(hashtag_params)
    @hashtag.user_id = current_user.id
    if @hashtag.save
      redirect_to user_hashtags_path       #respond_with(@hashtag)
    else
      respond_with(@hashtag)
    end
  end

  def update
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
      params.require(:hashtag).permit(:amount, :response, :tag, :charge_amount, :tag_type, 
        :enable_tweet, :description, images_attributes: [:avatar])
    end
end
