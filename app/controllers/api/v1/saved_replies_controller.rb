class Api::V1::SavedRepliesController < API::V1::BaseController

  def index
    begin
      render json: current_user.saved_replies.select('title, body') 
    rescue StandardError => e
      render json: [], status: 500
    end
  end

end