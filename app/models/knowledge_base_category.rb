class KnowledgeBaseCategory < ActiveRecord::Base
  extend FriendlyId

  friendly_id :name,  use: [:slugged, :history]

  has_many :knowledge_bases, class_name: 'KnowledgeBase', foreign_key: 'knowledge_base_category_id'
  validates :name, uniqueness: { case_sensitive: false}

  def should_generate_new_friendly_id?
    new_record?
  end
end
