class ListsController < ApplicationController
  include DashboardNotification

  before_action :set_list, only: [:show, :destroy, :add_member]
  before_action :set_notifications, except: [:destroy, :add_member]

  def index
    @lists = current_user.lists.where(segment: nil).paginate(per_page: PAGINATION_PER_PAGE, page: params[:page]).order(created_at: :desc)
    @lists.present? ? render_requested_format(@lists) : render(:no_lists)
  end

  # segment type list index action
  def segments
    @lists = current_user.segments.paginate(per_page: PAGINATION_PER_PAGE, page: params[:page]).order(created_at: :desc)
    @lists.present? ? render_requested_format(@lists) : render(:no_lists)
  end

  def show
    @list_members = @list.get_mcs

    # segment
    if @list.segment.present?
      @new_customer = User.new
      if @list.contact?
        @uid_type = @segment.sms? ? 'phone_number' : 'fb_page'
        @channel = @uid_type == 'phone_number' ? 'sms' : 'messenger'
      end
    end

    if @list_members.blank?
      flash[:error] = 'There are no members in the lists'
      # redirect_to lists_path(current_user)   or to customers for segments
      # render that there are no members in the lists
    else
      respond_to do |format|
        format.js { render partial: 'shared/index.js.erb', locals: { obj: obj } }
        format.html { render template: render_controller_action }
      end
    end
  end

  def add_member
    cc_id = params[:lists][:member_id]
    cc_type = 'MerchantCustomer' if params[:lists][:list_type] == 'customer'
    cc_type = 'MerchantContact' if params[:lists][:list_type] == 'contact'
    unless UserList.exists?(list_id: @list.id, customer_contact_type: cc_type, customer_contact_id: cc_id)
      @user_list = UserList.new(list_id: @list.id, customer_contact_type: cc_type, customer_contact_id: cc_id)
      if @user_list.save
        flash[:notice] = 'Member has been added.'
      else
        flash[:error] = 'Unable to add member to list.'
      end
    else
      flash[:notice] = 'Member is already a part of this list.'
    end
    redirect_to user_list_path(current_user, @list)
  end

  # this is used by segments/lists
  def destroy
    if @list.system?
      flash[:error] = 'You cannot delete a system generated segment.'
    elsif @list.campaign_lists.present?
      flash[:error] = 'Unable to delete a list/segment that has been attached to a campaign'
    else
     @list.destroy
      if @list.destroyed?
        flash[:success] = 'List/Segment has been deleted'
      else
        flash[:error] = 'Unable to delete list/segment'
      end
    end
    
    redirect_to ((@list.segment.blank?) ? user_lists_path(current_user) : user_segments_path(current_user))
  end

  private
    def set_list
      @list = List.find_by(id: params[:id])
    end

    def render_controller_action
      return 'lists/show' if @list.segment.blank?
      @selected_segment = @list.segment['base_query']
      @list_type = @list.list_type
      if @list.customer?
        @merchant_customers = @list_members
        "merchant_customers/index"
      else
        @merchant_contacts = @list_members
        "merchant_contacts/index"
      end
    end
end
