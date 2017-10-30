class SavedRepliesController < ApplicationController
  include DashboardNotification
  before_action :set_notifications, only: [:index]
  before_action :set_saved_reply, only: [:update, :destroy]

  def index
    @saved_replies = current_user.saved_replies.order(created_at: :desc)
                                .paginate(per_page: PAGINATION_PER_PAGE, page: params[:page])
    !@saved_replies.present? ? render_requested_format(@saved_replies) : render(:empty_saved_reply)
  end

  def update
    if @saved_reply.update(saved_reply_params)
      flash[:notice] = 'Reply was updated'
    else
      flash[:error] = 'Reply cannot be updated'
    end
    redirect_to user_saved_replies_path(current_user)
  end

  def destroy
    @saved_reply.destroy
    redirect_to user_saved_replies_path(current_user), flash: { notice: 'Reply was deleted' }
  end

  private

  def saved_reply_params
    params.require(:saved_reply).permit(:title, :body)
  end

  def set_saved_reply
    @saved_reply = SavedReply.find params[:id]
  end
end
