class KnowledgeBase < ActiveRecord::Base
  include SearchCop

    search_scope :search do
      attributes :title, :author, :raw_content
    end

  belongs_to :knowledge_base_category
end
