class KnowledgeBaseCategory < ActiveRecord::Base
  extend FriendlyId

  friendly_id :name,  use: [:slugged, :history]

  has_many :knowledge_bases
  validates_presence_of :name
  validates :name, uniqueness: { case_sensitive: false}

  def should_generate_new_friendly_id?
    new_record?
  end
end
