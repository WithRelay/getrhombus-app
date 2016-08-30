class Image < ActiveRecord::Base
  # This method associates the attribute ":avatar" with a file attachment

  has_many :image_ref, dependent: :destroy
  has_many :user, through: :image_ref, source: :imageable, source_type: 'User', dependent: :destroy
  has_many :hashtag, through: :image_ref, source: :imageable, source_type: 'Hashtag', dependent: :destroy
  has_many :message, through: :image_ref, source: :imageable, source_type: 'Message', dependent: :destroy

  has_attached_file :avatar, styles: {
    thumb: '100x100>',
    square: '200x200#',
    medium: '300x300>'
  }

  # Validate the attached image is image/jpg, image/png, etc
  validates_attachment_content_type :avatar, :content_type => /\Aimage\/.*\Z/
end