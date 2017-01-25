class KnowledgeBase < ActiveRecord::Base
  include SearchCop
  belongs_to :knowledge_base_category
  validates :title, uniqueness: { case_sensitive: false}
  validates :url, uniqueness: { case_sensitive: false}
  
  search_scope :search do
    attributes :title, :author, :raw_content
  end

end
