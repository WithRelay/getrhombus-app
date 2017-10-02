class KnowledgeBase < ActiveRecord::Base
  #extend FriendlyId

  #friendly_id :title,  use: [:slugged, :history]

  belongs_to :knowledge_base_category
  validates_presence_of :title
  validates :title, uniqueness: { case_sensitive: false }

end
