class KnowledgeBase < ActiveRecord::Base

  belongs_to :knowledge_base_category
  validates :title, uniqueness: { case_sensitive: false}
  validates :url, uniqueness: { case_sensitive: false}

end
