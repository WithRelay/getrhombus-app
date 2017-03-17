module KnowledgeBaseCategoriesHelper

  def breadcrumb_item
    request.url.split('/').last.gsub('-', ' ').titleize
  end
  
end
