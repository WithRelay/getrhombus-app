class Api::V1::SavedRepliesController < API::V1::BaseController

  def index
    begin
      sql = ActiveRecord::Base.send(:sanitize_sql_array,
              ["SELECT title, body from saved_replies where user_id = ?", current_user.id ])
            
      render json: SavedReply.connection.select_all(sql)
    rescue StandardError => e
      render json: [], status: 500
    end
  end

end