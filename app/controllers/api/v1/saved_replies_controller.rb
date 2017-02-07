class Api::V1::SavedRepliesController < API::V1::BaseController

  before_action :set_save_reply, except: [:index]

  def index
    begin
      render json: current_user.saved_replies.select('title, body') 
    rescue StandardError => e
      render json: [], status: 500
    end
  end

  def edit
  	response = @user_save_reply ? { save_reply:  @user_save_reply, status: 200 } : { save_reply: [], status: 400 }
  	render json: response
  end

  def save
    update_save_reply = @user_save_reply.update_attributes(save_reply_params)
    response= update_save_reply ? { notice: "Saved reply updated successfully." , status: 200 } : {notice: "Couldn't Update", status: 400 }
    render json: response
  end

  private 

  def set_save_reply
    @user_save_reply = current_user.saved_replies.find_by_id(params[:saved_reply][:id])
  end

  def save_reply_params
    params.require(:saved_reply).permit(:title, :body)
  end

end 