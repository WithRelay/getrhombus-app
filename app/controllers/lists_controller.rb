class ListsController < ApplicationController
  include DashboardNotification

  before_action :set_list, only: [:show, :edit, :update, :destroy, :update_user_list]
  before_action :set_notifications, except: [:destroy]

  def index
    @lists = current_user.lists.where(segment: nil).paginate(per_page: PAGINATION_PER_PAGE,
                                                    page: params[:page])

    if @lists.present?
      respond_to do |format|
        format.html
        format.js { render partial: 'shared/index.js.erb', locals: { obj: @lists } }
      end
    else
      render :empty_list
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

  def remove_customer_contact

  end

  def update
    if @list.update_attributes(list_params)
      flash[:notice] = 'List was successfully updated.'
    else
      flash[:error] = @list.errors.full_messages
    end
    redirect_to lists_path(current_user)
  end

  def update_user_list
    list_member_id = params[:lists][:list_member]
    @list.user_lists.build(user_id: list_member_id)
    if list_member_id.present? && @list.save
      flash[:notice] = 'List was successfully updated.'
    else
      flash[:error] = 'List member could not updated'
    end
    redirect_to list_path(current_user, @list)
  end


  def delete_segment
    if get_lists.present? && get_lists.delete_all
      flash[:notice] = "segment was successfully deleted"
    else
      flash[:error] = 'Sorry segment cannot deleted'
    end
    redirect_to  segments_user_path(current_user)
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
    @segments = current_user.lists.where.not(segment: nil)
    render :empty_list if @segments.empty?
  end

  private
    def set_list
      @list = List.find_by_id(params[:id])
    end

    def get_lists
      list_ids = params[:list_id].split(',').flatten
      # sql query states that find list where id is same as array of ids from params
      # and check if those lists have associated record campaign_lists or not
      # it will return the list if there is no associated record campaign_lists
      List.where(id: list_ids).where('id NOT IN (SELECT list_id FROM campaign_lists where
      list_id IN(?))', list_ids)
    end

    def list_params
      params.require(:list).permit(:name)
    end
end
