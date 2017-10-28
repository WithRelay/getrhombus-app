class Document < ActiveRecord::Base

  belongs_to :user
  has_attached_file :attachment
  after_validation :clean_up_paperclip_errors
  validates_attachment_content_type :attachment, content_type: ["text/csv", 'text/plain', 'application/vnd.ms-excel']

  private

  # This is because paperclip duplicates error messages
  # See: https://github.com/thoughtbot/paperclip/pull/1554 and
  # https://github.com/thoughtbot/paperclip/commit/2aeb491fa79df886a39c35911603fad053a201c0
  def clean_up_paperclip_errors
    errors.delete(:attachment)
    if errors[:attachment_content_type].present?
      errors.add(:base, 'Please save file as a CSV and re-upload') 
      errors.delete(:attachment_content_type)
    end
  end

  
end