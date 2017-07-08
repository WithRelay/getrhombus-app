class Api::V1::SavedRepliesController < API::V1::BaseController

  before_action :set_save_reply, except: [:index]

  def index
    begin
      render json: current_user.saved_replies.select('id, title, body')
    rescue StandardError => e
      render json: [], status: 500
    end
  end

  def create
    saved_reply = current_user.saved_replies.new(save_reply_params)
    if saved_reply.save
      render json: { notice: "Reply has been created" }
    else
      render json:{ error: saved_reply.errors.messages , data: saved_reply , status: 500 }
    end
  end

  private

  def set_save_reply
    @user_save_reply = current_user.saved_replies.find_by_id(params[:saved_reply][:id])
  end

  def save_reply_params
    params.require(:saved_reply).permit(:title, :body)
  end

end
