class ListsController < ApplicationController
  before_action :set_list, only: [:show, :edit, :update, :destroy]
  before_action :find_user_lists, only: [:index]
  include DashboardNotification
  before_action :set_notifications, except: [:destroy]
  respond_to :html

  def index
    respond_with(@lists)
    render 'empty_list' if @lists.empty? and return
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
    if get_lists.present? && get_lists.delete_all
      flash[:notice] = "List was successfully deleted"
    else
      flash[:error] = 'Sorry list cannot deleted'
    end
     redirect_to lists_path(current_user)
   end

  def segments
    @segments = current_user.lists.where(segment: true)
  end

  private
    def set_list
      @list = List.find(params[:id])
    end

    def get_lists
      list_ids = params[:list_id].split(',')
      # sql query states that find list where id is same as array of ids from params
      # and check if those lists have associated record campaign_lists or not
      # it will return the list if there is no associated record campaign_lists
      List.where(id: list_ids).where('id NOT IN (SELECT list_id FROM campaign_lists where
                                      list_id IN(?))', list_ids)
    end

    def list_params
      params.require(:list).permit(:id,:name,:user_id)
    end

    def find_user_lists
      @lists = List.where(user_id:current_user.id)
    end
end
