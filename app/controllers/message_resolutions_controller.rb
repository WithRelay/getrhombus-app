class MessageResolutionsController < ApplicationController
  before_action :set_message_resolution, only: [:update, :destroy]

  def new
    @message_resolution = current_user.message_resolutions.build
  end

  def index
    # With c_id, we know the resolution is in use and so should not be deleted
    @message_resolutions = current_user.message_resolutions
                            .joins("LEFT JOIN conversations c ON message_resolutions.id = c.message_resolution_id")
                            .select('message_resolutions.id as id, title, c.id as c_id')
  end

  def create
    @message_resolution = current_user.message_resolutions.build(message_resolution_params)
    if @message_resolution.save
      flash[:notice] = 'Message Resolution was saved'
      redirect_to user_message_resolutions_path
    else
      flash[:error] = 'Message Resolution cannot be saved'
      render :new
    end
    
  end

  def update
    if @message_resolution.update(message_resolution_params)
      flash[:notice] = 'Message Resolution was updated'
    else
      flash[:error] = 'Message Resolution cannot be updated'
    end
    redirect_to user_message_resolutions_path
  end

  # only if has not been used before
  def destroy
    if Conversation.exists?(message_resolution_id: params[:id]) 
      redirect_to user_message_resolutions_path, flash: { error: 'Message Resolution is attached to a conversation' }
    else
      @message_resolution.destroy
      redirect_to user_message_resolutions_path, flash: { notice: 'Message Resolution was deleted' }  
    end  
  end

  private

    def message_resolution_params
      params.require(:message_resolution).permit(:title)
    end

    def set_message_resolution
      @message_resolution = MessageResolution.find params[:id]
    end
end
