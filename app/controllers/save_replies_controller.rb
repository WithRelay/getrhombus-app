class SaveRepliesController < ApplicationController
  def new
    @save_reply = current_user.save_replies.build
  end

  def index
    @save_replies = current_user.save_replies
    @save_reply = current_user.save_replies.build
  end

  def create
    @save_reply = current_user.save_replies.build(save_reply_params)
     if @save_reply.save
      flash[:notice] = 'Saves successfully'
    else
      flash[:error] = 'Can not save Reply'   
    end
    redirect_to user_path(current_user)
  end

  def destroy
    save_reply = current_user.save_replies.find_by_id params[:id]
    save_reply.destroy
    redirect_to user_path(current_user)
  end

  private
  def save_reply_params
    params.require(:save_reply).permit(:title, :body)
  end
end
