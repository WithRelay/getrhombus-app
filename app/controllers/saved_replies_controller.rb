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
      redirect_to user_saved_replies_path
    else
      flash[:error] = 'Reply cannot be saved'
      render :new
    end
    
  end

  def update
    @saved_reply.update(saved_reply_params)
    redirect_to user_saved_replies_path, flash: { notice: 'Reply was updated'}
  end

  def destroy
    @saved_reply.destroy
    redirect_to user_saved_replies_path, flash: { notice: 'Reply was deleted'}
  end

  private

    def saved_reply_params
      params.require(:saved_reply).permit(:title, :body)
    end

    def set_saved_reply
      @saved_reply = SavedReply.find params[:id]
    end
end
