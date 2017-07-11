class KnowledgeBasesController < ApplicationController
  before_action :set_kb
  
  def show
  end

  private

  def set_kb
    @knowledge_base = KnowledgeBase.find_by(slug: params[:slug])
  end

end
