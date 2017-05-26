class Document < ActiveRecord::Base

  belongs_to :user
  has_attached_file :attachment
  validates_attachment :attachment, content_type: { content_type: "text/csv" }


end