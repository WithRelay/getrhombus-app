class Api::V1::HashtagsController < API::V1::BaseController

	def find
		begin
			sql = ActiveRecord::Base.send(:sanitize_sql_array, 
					["SELECT id, description, tag FROM hashtags where description LIKE concat('%', ?, '%') or 
						tag like concat('%', ?, '%') and user_id = ?", params[:query], params[:query], current_user.id ])
						#tag like concat('%', ?, '%') and user_id = ?", params[:query], params[:query], '23' ])

			results = Hashtag.connection.select_all(sql)
			results = results.map { |h| { description: h["description"], tag: h['tag'], id: h['id'] } }		
		  render json: { "hashtags" => results }, status: 200
		rescue StandardError => e
			render json: { error: "Unable to find your hashtags" }, status: 500
		end
	end

	def create
		if Hashtag.create(name: params[:name] , tag: params[:tag])
			render json: output
		else
			render json: { "error": "unable to create hashtag" }, status: 500
		end 
	end


end