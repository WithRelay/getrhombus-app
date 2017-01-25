class KnowledgeBaseCategory < ActiveRecord::Base
  extend FriendlyId

  friendly_id :name, use: :slugged

  has_many :knowledge_bases
end
