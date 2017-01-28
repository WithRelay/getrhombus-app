class Api::V1::KnowledgeBasesController < API::V1::BaseController
  skip_before_action :verify_authenticity_token

  def index
  	if params[:query].present? 
  		q = "%#{params[:query].downcase}%"
  		kb = KnowledgeBase.where("lower(raw_content) LIKE (?) or lower(title) LIKE (?)", q, q)    
  	else
  		KnowledgeBase.all
  	end
	render json: { results: kb }
  end

  def article_rating
    kb = get_kb if params[:title]
    if params[:query] === 'Yes'
      kb.upvotes  = kb.upvotes ? kb.upvotes + 1 : 1
    else
     kb.downvotes = kb.downvotes ? kb.downvotes + 1 : 1
    end
    kb.save
    render json: { results: kb}
  end

  private
  def get_kb
    KnowledgeBase.find_by_title(params[:title])
  end
end
