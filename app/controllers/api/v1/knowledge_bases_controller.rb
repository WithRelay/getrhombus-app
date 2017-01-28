class Api::V1::KnowledgeBasesController < API::V1::BaseController
 
  def index
  	if params[:query].present? 
  		q = "%#{params[:query].downcase}%"
  		kb = KnowledgeBase.where("lower(raw_content) LIKE (?) or lower(title) LIKE (?)", q, q)    
  	else
  		KnowledgeBase.all
  	end
	render json: { results: kb }
  end
end
