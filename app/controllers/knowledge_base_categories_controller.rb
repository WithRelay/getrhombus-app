class KnowledgeBaseCategoriesController < ApplicationController
  before_action :set_kb, only: [:edit, :show, :update]

  def index
    @knowledge_base_categories = KnowledgeBaseCategory.all
  end

  def new
    @knowledge_base_category = KnowledgeBaseCategory.new
  end

  def create
    @knowledge_base_category = KnowledgeBaseCategory.new(kb_params)
    if @knowledge_base_category.save
      flash[:notice] = 'Knowledge base category created successfully.'
      redirect_to user_knowledge_base_categories_path(current_user)
    else
      flash[:error] = 'Something went wrong'
      render :new
    end
  end

  def edit
  end

  def update
    if @knowledge_base_category.update(kb_params)
      flash[:notice] = 'Knowledge base category updated.'
      redirect_to user_knowledge_base_categories_path(current_user)
    else
      flash[:error] = 'Something went wrong'
      render :edit
    end
  end

  def show
    @kb_list = @knowledge_base_category.knowledge_bases
  rescue StandardError
    redirect_to to_404_path
  end

  private

  def kb_params
    params.require(:knowledge_base_category).permit(:name)
  end

  def set_kb
    @knowledge_base_category = KnowledgeBaseCategory.find_by(slug: params[:slug])
  end

end
