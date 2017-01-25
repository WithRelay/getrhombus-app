class KnowledgeBaseCategory < ActiveRecord::Base
  extend FriendlyId

  friendly_id :name, use: :slugged

  has_many :knowledge_bases, class_name: 'KnowledgeBase', foreign_key: 'knowledge_base_category_id'
end
