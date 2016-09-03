class Image < ActiveRecord::Base
  # This method associates the attribute ":avatar" with a file attachment
  attr_reader :avatar_remote_url

  # https://blog.codeship.com/how-to-use-rails-active-job/
  # https://github.com/jrgifford/delayed_paperclip

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

  def avatar_remote_url=(url_value)
    self.avatar = URI.parse(url_value)
    # Assuming url_value is http://example.com/photos/face.png
    # avatar_file_name == "face.png"
    # avatar_content_type == "image/png"
    @avatar_remote_url = url_value
  end
end