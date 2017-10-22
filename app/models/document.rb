class Document < ActiveRecord::Base

  belongs_to :user
  has_attached_file :attachment
  validates_attachment :attachment, content_type: { content_type: ["text/csv", 'application/vnd.ms-excel'], message: "Please save file as a CSV." }


end