class HashtagsController < ApplicationController
  include DashboardNotification
  before_action :set_notifications, only: [:index, :new, :edit, :create]
  before_action :set_hashtag, only: [:edit, :update, :destroy, :change_status]
  respond_to :html

  def index
    @hashtags = current_user.hashtags.order(created_at: :desc).paginate(per_page: PAGINATION_PER_PAGE, page: params[:page])
    @hashtags.present? ? render_requested_format(@hashtags) : render(:empty_hashtag)
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
    unless plan_name_exists?
      if @hashtag.save
        if @hashtag.create_plan_for_recurring_tag(current_user)
          redirect_to user_hashtags_path, flash: { notice: "Hashtag created!" }
        else
          flash[:error] = "We're unable to create the hashtag and associated recurring plan."
          @hashtag.destroy
          render :new
        end
      else
        flash[:error] = @hashtag.errors.messages.present? ? @hashtag.errors.full_messages : "We couldn't create the hashtag."
        respond_with(@hashtag)
      end
    else
      flash[:error] = "A recurring plan with this tag name already exists."
      respond_with(@hashtag)
    end
  end

  def update
    unless plan_name_exists?
      if @hashtag.update_plan_for_recurring_tag(hashtag_params[:name])
        if @hashtag.update(hashtag_params)
          redirect_to user_hashtags_path, flash: { notice: "Hashtag Updated!" }
        else
          flash[:error] = @hashtag.errors.messages.present? ? @hashtag.errors.full_messages : "We couldn't update the hashtag"
          respond_with(@hashtag)
        end
      else
        flash[:error] = "A recurring plan with this tag name already exists."
        respond_with(@hashtag)
      end
    else
      flash[:error] = "A recurring plan with this tag name already exists."
      respond_with(@hashtag)
    end
  end

  def change_status
    if @hashtag.present?
      status = @hashtag.active? ? 0 : 1
      @hashtag.update_attribute('status', status)
    end
    flash[:notice] = "Hashtag status has been changed"
    redirect_to user_hashtags_path
  end

  def destroy
    unless @hashtag.is_mentioned?
      re = @hashtag.delete_plan_for_recurring_tag(current_user)
      if re.first
        if @hashtag.destroy
          flash[:notice] = "Hashtag Deleted"
        else
          flash[:error] = "We cannot delete the hashtag"
        end
      else
        flash[:error] = re.second
      end
    else
      flash[:error] = 'We cannot delete a hashtag that has been mentioned'
    end
    redirect_to user_hashtags_path
  end


  private

    def set_hashtag
      @hashtag = Hashtag.find(params[:id])
    end

    def plan_name_exists?
      return false unless @hashtag.recurring_payment_tag?
      Plan.exist?(['merchant_id = ? and lower(name) = ?', current_user.id, "#{@hashtag.tag}"])
    end

    def hashtag_params
      params.require(:hashtag).permit(:amount, :status, :name, :response, :tag, :charge_amount, :tag_type, :interval,
        :enable_tweet, :description, images_attributes: [:avatar]).tap do |h|
          h[:tag].prepend('#') if h[:tag].present? && h[:tag].chr != "#"
          h[:charge_amount] = h[:charge_amount].to_i
          h[:tag_type] = h[:tag_type].to_i
          h[:status] = h[:status] || 1
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
