class ListsController < ApplicationController
  before_action :set_list, only: [:show, :edit, :update, :destroy]
  before_action :find_user_lists, only: [:index]
  respond_to :html

  def index
    respond_with(@lists)
  end

  def show
    @users = @list.get_users
    respond_with(@list,@users)
  end

  def new
    @list = List.new
    respond_with(@list)
  end

  def edit
  end

  def create
    @list = List.new(list_params)
    flash[:notice] = 'List was successfully created.' if @list.save
    respond_with(@list)
  end

 
  def update
    flash[:notice] = 'List was successfully updated.' if @list.update(list_params)
    respond_with(@list)
  end

  # Deletes only lists that are not in an active campaign
  # Begins by checking to see if a campaign list exists with the list id
  # If not, deletes the list as usual
  def destroy
    if CampaignList.where(:list_id => @list.id).any?
      flash[:notice] = "This list cannot be deleted as it is part of a campaign"
      respond_with(@list)
    else
      @list.destroy
      flash[:notice] = "List was successfully deleted"
      respond_with(@list)
    end
  end

  private
    def set_list
      @list = List.find(params[:id])
    end

    def list_params
      params.require(:list).permit(:id,:name,:user_id)
    end

    def find_user_lists
      @lists = List.where(user_id:current_user.id)
    end
end
