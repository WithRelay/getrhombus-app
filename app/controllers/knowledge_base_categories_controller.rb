class KnowledgeBaseCategoriesController < ApplicationController
  def index
    @knowledge_base_categories = KnowledgeBaseCategory.all
  end

  def create
    @kb_category = KnowledgeBaseCategory.new
  end

  def edit
  end

  def update
  end

  def show
    # @kb_list = KnowledgeBase.search(params['search'])
    @kb_list = KnowledgeBase.all
  end
end
