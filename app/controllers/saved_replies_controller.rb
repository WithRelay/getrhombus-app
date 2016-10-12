class SavedRepliesController < ApplicationController
  before_action :check_user_present

  def new
    @saved_reply = current_user.saved_replies.build
  end

  def index
    @saved_replies = current_user.saved_replies
  end

  def create
    @saved_reply = current_user.saved_replies.build(saved_reply_params)
    if @saved_reply.save
      flash[:notice] = 'Reply was saved'
    else
      flash[:error] = 'Reply cannot be saved'   
    end
    redirect_to user_saved_replies_path
  end

  def destroy
    saved_reply = current_user.saved_replies.find_by_id params[:id]
    saved_reply.destroy
    redirect_to user_saved_replies_path
  end

  private
  
    def saved_reply_params
      params.require(:saved_reply).permit(:title, :body)
    end

    def check_user_present
      if current_user.nil?
        redirect_to signin_path
      end
    end
end
