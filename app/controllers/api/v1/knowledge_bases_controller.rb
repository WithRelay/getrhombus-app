class Api::V1::KnowledgeBasesController < API::V1::BaseController
  
  def index
  	if params[:query].present? 
  		q = "%#{params[:query].downcase}%"
  		@kbs = KnowledgeBase.where("lower(raw_content) LIKE (?) or lower(title) LIKE (?)", q, q)    
  	else
  		KnowledgeBase.all
  	end
	  render json: { results: @kbs }
  end

  def rating
    if get_kb
      column = params[:vote] == 'Yes' ? :upvotes : :downvotes
      @kb.increment(column, 1).save if params[:vote].present?
    end
    render json: { results: @kb }
  end

  private
  
  def get_kb
    @kb = KnowledgeBase.find_by(url: params[:url])
  end

end
