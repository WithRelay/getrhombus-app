class KnowledgeBase < ActiveRecord::Base
  include SearchCop

  search_scope :search do
    attributes :title, :raw_content

    options :title, :type => :fulltext
    options :raw_content, :type => :fulltext
  end

  belongs_to :knowledge_base_category
  validates :title, uniqueness: { case_sensitive: false}
  validates :url, uniqueness: { case_sensitive: false}

end
