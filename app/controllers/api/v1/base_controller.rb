class API::V1::BaseController < ApplicationController

  # before_action :http_basic_authentication
  # do current_user or token test here and set as current_user

  ALLOWED_MIME_TYPE = %w(image/jpg, image/png, image/jpeg)
  ALLOWED_SIZE_IN_BYTES  = 4718592

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

  def find_image(find_by_hash)
     ImageRef.where(find_by_hash).first
  end

  def valid_uploaded_images(image)
    (ALLOWED_MIME_TYPE.include?(image.content_type) && (image.size < ALLOWED_SIZE_IN_BYTES))
  end



end
