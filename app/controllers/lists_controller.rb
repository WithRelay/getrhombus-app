class ListsController < ApplicationController
  before_action :set_list, only: [:show, :edit, :update, :destroy]
  before_action :find_user, only: [:index]
  respond_to :html

  def index
    @lists = List.all
    respond_with(@lists)
  end

  def show
    customers = UserList.where(:list_id => @list.id)
    @users = Array.new
    customers.each do |c|
      @users.push(User.find(c.user_id))
    end
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
  # else if the list is associated with an active campaign, the delete operation
  # is aborted
  def destroy
    if CampaignList.where(:list_id => @list.id).any?
      if CampaignList.where(list_id:@list.id).first.campaign.status == "active"
        flash[:notice] = "This list cannot be deleted as it is part of an active campaign"
        respond_with(@list)
      else 
        @list.destroy
        flash[:notice] = "List was successfully deleted"
        respond_with(@list)
      end
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

    def find_user
      @list = List.find_by(user_id:current_user.id)
    end
end
