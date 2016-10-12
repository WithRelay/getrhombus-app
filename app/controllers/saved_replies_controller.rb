class SavedRepliesController < ApplicationController
  before_action :set_saved_reply, only: [:update, :destroy]

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

  def update
    @saved_reply.update(saved_reply_params)
    redirect_to user_saved_replies_path, notice: "Updated" 
  end

  def destroy
    @saved_reply.destroy
    redirect_to user_saved_replies_path
  end

  private

    def saved_reply_params
      params.require(:saved_reply).permit(:title, :body)
    end

    def set_saved_reply
      @saved_reply = SavedReply.find params[:id]
    end
end
