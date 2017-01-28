class Api::V1::KnowledgeBasesController < API::V1::BaseController
  def search
    kb = KnowledgeBase.search(params[:show][:search])
    # kb = User.where("raw_content LIKE (?)", "%#{params[:show][:search]}%")
    render json: { knowledge_bases: kb }
  end
end
