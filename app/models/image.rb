class Image < ActiveRecord::Base

  # https://blog.codeship.com/how-to-use-rails-active-job/
  # https://github.com/jrgifford/delayed_paperclip
  IMAGE_VERSIONS = { thumb: '100x100>', square: '200x200#', medium: '300x300>' }

  has_many :image_refs, dependent: :destroy
  has_many :users, through: :image_refs, source: :imageable, source_type: 'User' #, dependent: :destroy
  has_many :hashtags, through: :image_refs, source: :imageable, source_type: 'Hashtag' #, dependent: :destroy
  has_many :messages, through: :image_refs, source: :imageable, source_type: 'Message' #, dependent: :destroy
  has_many :fb_messages, through: :image_refs, source: :imageable, source_type: 'FbMessage' #, dependent: :destroy

  has_attached_file :avatar, styles: lambda { |i| i.instance.uploaded_as.present? ?
                                              IMAGE_VERSIONS : Hash[*Image::IMAGE_VERSIONS.first]
                                            }
  # Validate the attached image is image/jpg, image/png, etc
  validates_attachment_content_type :avatar, :content_type => /\Aimage\/.*\Z/
  validate :campaign_file_attachment, if: proc { |i| i.uploaded_as.present? }

  enum uploaded_as: [:inline,  :attachment]

  def avatar_from_remote_url(url_value)
    self.avatar = URI.parse(url_value)
    # Assuming url_value is http://example.com/photos/face.png
    # avatar_file_name == "face.png"
    # avatar_content_type == "image/png"
  end

  # since for twilio_media we need to use basic authentication
  def avatar_for_twilio_media(url_value)
    self.avatar = open(URI.parse(url_value), :http_basic_authentication => [TextingService::TWILIO_API_KEY, TextingService::TWILIO_API_SECRET])
  end

  def campaign_file_attachment
    errors.add(:avatar, 'size should not be more than 4.5 MB') if self.avatar_file_size > 4.5.megabytes
  end
end
