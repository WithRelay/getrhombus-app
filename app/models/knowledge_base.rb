class KnowledgeBase < ActiveRecord::Base
  include SearchCop

  search_scope :search do
    attributes :title, :raw_content
  end

  belongs_to :knowledge_base_category
end
