class KnowledgeBaseCategoriesController < ApplicationController
  def index
    @knowledge_base_categories = KnowledgeBaseCategory.all
  end

  def new
    if KnowledgeBaseCategory.create({name: params[:name]})
      flash[:notice] = 'Knowledge base category created successfully.'
    else
      flash[:error] = 'Something went wrong'
    end
    redirect_to knowledge_base_path
  end

  def edit
  end

  def update
  end

  def show
    @kb_list = if params[:show].present?
      kb ? kb.knowledge_bases.search(params[:show][:search]) : []
    elsif params[:search].present?
      KnowledgeBase.search(params['search'])
    elsif params[:slug].present?
      kb ? kb.knowledge_bases : ''
    else
      KnowledgeBase.all
    end
  end

  private
  def kb
    KnowledgeBaseCategory.find_by(slug: params[:slug])
  end

end
