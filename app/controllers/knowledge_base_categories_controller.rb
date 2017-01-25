class KnowledgeBaseCategoriesController < ApplicationController
  def index
    @knowledge_base_categories = KnowledgeBaseCategory.all
  end

  def create
  end

  def edit
  end

  def relay_docs
  end

  def relay_docs_article
  end

  def relay_docs_categories
  end
end
