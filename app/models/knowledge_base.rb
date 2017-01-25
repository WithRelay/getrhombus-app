class KnowledgeBase < ActiveRecord::Base
  include SearchCop

  search_scope :search do
    attributes :title, :raw_content
  end

  belongs_to :knowledge_base_category
  validates :title, uniqueness: { case_sensitive: false}
  validates :url, uniqueness: { case_sensitive: false}
  
  search_scope :search do
    attributes :title, :author, :raw_content
  end

end
