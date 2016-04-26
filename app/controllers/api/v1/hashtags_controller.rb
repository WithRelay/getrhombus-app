class Api::V1::HashtagsController < API::V1::BaseController

	def find
		sql = ActiveRecord::Base.send(:sanitize_sql_array, 
				["SELECT id, name, tag FROM hashtags where name LIKE concat('%', ?, '%') or 
					tag like concat('%', ?, '%') and user_id = ?", params[:query], params[:query], current_user.id ])
					#tag like concat('%', ?, '%') and user_id = ?", params[:query], params[:query], '23' ])

		results = Hashtag.connection.select_all(sql)

		render json: { "hashtags" => results } and return if results.empty?

		hashtags_array = []
		
		results.each do |h|			
			hashtags_array.push({ name: h["name"], tag: h['tag'], id: h['id'] })
		end

	    output = { "hashtags" => hashtags_array }
		render json: output
	end

	def create
		if Hashtag.create(name: params[:name] , tag: params[:tag])
			render json: output
		else
			render json: { "error": "unable to create hashtag" }, status: 500
		end 
	end


end