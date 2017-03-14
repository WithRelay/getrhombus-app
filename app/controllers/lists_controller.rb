class ListsController < ApplicationController
  include DashboardNotification

  before_action :set_list, only: [:show, :edit, :update, :destroy]
  before_action :set_notifications, except: [:destroy]

  def index
    @lists = current_user.lists.where(segment: nil).paginate(per_page: PAGINATION_PER_PAGE,
                                                    page: params[:page])
    render :empty_list if (@lists.empty? && params[:page].nil?)
    respond_to do |format|
      format.js { render partial: 'shared/index.js.erb', locals: { obj: @lists } }
      format.html
    end
  end

  def show
    @list_members = @list.get_users
  end

  def new
    @list = current_user.lists.build
  end

  def edit
  end

  def create
    @list = current_user.lists.build(list_params)
    flash[:notice] = 'List was successfully created.' if @list.save
    respond_with(@list)
  end


  def update
    if @list.update_attributes(name: list_params[:list_name])
      flash[:notice] = 'List was successfully updated.'
    else
      flash[:error] = @list.errors.full_messages
    end
    redirect_to lists_path(current_user)
  end

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
      @list = List.find_by_id(params[:id])
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
      params.require(:list).permit(:list_name)
    end
end
