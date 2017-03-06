class HashtagsController < ApplicationController
  before_action :set_hashtag, only: [:show, :edit, :update, :destroy]
  include DashboardNotification
  before_action :set_notifications
  respond_to :html, :js

  def index
    @hashtags = current_user.hashtags.paginate(per_page: PAGINATION_PER_PAGE,
                                               page: params[:page])
                                               .order('updated_at DESC')
    render 'empty_hashtag' unless @hashtags.present?
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
    if @hashtag.save
      if @hashtag.create_plan_for_recurring_tag(current_user)
        redirect_to user_hashtags_path, flash: { notice: "Hashtag created!" }
      else
        flash[:error] = "We're unable to create a plan for this recurring hashtag."
        @hashtag.destroy
        render :new
      end
    else
      flash[:error] = @hashtag.errors.messages.present? ? @hashtag.errors.full_messages : "We couldn't create the hashtag"
      respond_with(@hashtag)
    end
  end

  def update
    if @hashtag.update(hashtag_params)
      redirect_to user_hashtags_path, flash: { notice: "Hashtag Updated!" }
    else
      flash[:error] = @hashtag.errors.messages.present? ? @hashtag.errors.full_messages : "We couldn't update the hashtag"
      respond_with(@hashtag)
    end
  end

  def destroy
    if !@hashtag.is_mentioned?
      re = @hashtag.delete_plan_for_recurring_tag(current_user)
      if re.first
        if @hashtag.destroy
          redirect_to(user_hashtags_path, flash: { notice: "Hashtag Deleted" }) and return
        else
          flash[:error] = "We cannot delete the hashtag"
        end
      else
        flash[:error] = re.second
      end
    else
      flash[:error] = 'We cannot delete a hashtag that has been mentioned'
    end
    respond_with(@hashtag)
  end


  private
    def set_hashtag
      @hashtag = Hashtag.find(params[:id])
    end

    def hashtag_params
      params.require(:hashtag).permit(:amount, :status, :name, :response, :tag, :charge_amount, :tag_type, :interval,
        :enable_tweet, :description, images_attributes: [:avatar]).tap do |h|
          h[:charge_amount] = h[:charge_amount].to_i
          h[:tag_type] = h[:tag_type].to_i
          h[:status] = h[:status].to_i
          if h[:tag_type] == 2
            interval_ary = h[:interval].split("_")
            h[:interval] = interval_ary[0]
            h[:interval_count] = interval_ary[1]
          elsif h[:tag_type] == 0
            h[:charge_amount] = nil
            h[:amount] = nil
            h[:interval] = nil
          else
            h[:interval] = nil
          end
      end
    end
end
