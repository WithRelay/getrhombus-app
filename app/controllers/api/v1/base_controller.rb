class API::V1::BaseController < ApplicationController

  # before_action :http_basic_authentication
  # do current_user or token test here and set as current_user

  ALLOWED_MIME_TYPE = %w(image/jpg image/png image/jpeg)
  ALLOWED_SIZE_IN_BYTES = 4718592

  before_action :cors_preflight_check
  after_action :cors_set_access_control_headers

  def cors_set_access_control_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'POST, GET, PUT, DELETE, OPTIONS'
    headers['Access-Control-Allow-Headers'] = 'Origin, Content-Type, Accept, Authorization, Token'
    headers['Access-Control-Max-Age'] = "1728000"
  end

  def cors_preflight_check
    if request.method == 'OPTIONS'
      headers['Access-Control-Allow-Origin'] = '*'
      headers['Access-Control-Allow-Methods'] = 'POST, GET, PUT, DELETE, OPTIONS'
      headers['Access-Control-Allow-Headers'] = 'X-Requested-With, X-Prototype-Version, Token'
      headers['Access-Control-Max-Age'] = '1728000'
      render :text => '', :content_type => 'text/plain'
    end
  end

  private

  def current_user_id
    current_user.id
  end

  def find_image_ref(find_by_hash)
     ImageRef.where(find_by_hash).first
  end

  def valid_image_upload(image)
    (ALLOWED_MIME_TYPE.include?(image.content_type) && (image.size < ALLOWED_SIZE_IN_BYTES))
  end

  def validation_messages(image)
    # Uploaded_as is an enum 0 refers to inline and 1 refers to attachment.
    # It is important to verify image whether it is inline and attachment while sending campaign via mandrill
    image_avatar = Image.new({ avatar: image, uploaded_as: 0 })
    if valid_image_upload(image) && image_avatar.save
      { status: 200, message: 'success', image_id: image_avatar.id, image_url: image_avatar.avatar.url }
    else
      { status: 401, message: 'sorry file type/size is not supported' }
    end
  end
end
