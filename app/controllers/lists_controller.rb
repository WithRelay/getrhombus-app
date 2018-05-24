# Controller ctions for customer/contacts list and segments
class ListsController < ApplicationController
  include DashboardNotification

  before_action :set_list, only: [:show, :destroy, :add_member]
  before_action :set_notifications, except: [:destroy, :add_member]

  def index
    @lists = current_user.lists.campaign.where(segment: nil).paginate(per_page: PAGINATION_PER_PAGE, page: params[:page]).order(created_at: :desc)
    @lists.present? ? render_requested_format(@lists) : render(:no_lists)
  end

  # segment type list index action
  def segments
    @list_segments = current_user.segments.campaign.paginate(per_page: PAGINATION_PER_PAGE, page: params[:page]).order(created_at: :desc)
    if @list_segments.present?
      respond_to do |format|
        format.js { render partial: 'list_segments.js.erb', locals: { obj: @list_segments } }
        format.html
      end
    else
      render(:no_lists)
    end
  end

  def show
    if @list
      
      if params[:search].present? && params[:commit].to_s.casecmp('search').zero?
        @list_members = @list.search_members(params[:search], params[:page])
      else
        @list_members = @list.get_mcs(params[:page])
      end

      # segment
      if @list.is_segment?
        @new_customer = User.new
        @selected_segment_id = @list.id
        @list_type = @list.list_type
        if @list.contact?
          @uid_type = @list.sms? ? 'phone_number' : 'fb_page'
          @channel = @uid_type == 'phone_number' ? 'sms' : 'messenger'
        end
      end
    end

    if @list_members.blank?
      render(:no_members)
    else
      respond_to do |format|
        format.js { render partial: 'list_members.js.erb', locals: { obj: @list_members } }
        format.html
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

    redirect_to ((!@list.is_segment?) ? user_lists_path(current_user) : user_segments_path(current_user))
  end

  private
    def set_list
      @list = List.find_by(id: params[:id])
    end

    def render_show_controller_action
      return 'lists/show' if !@list.is_segment?
      if @list.customer?
        @merchant_customers = @list_members
        "merchant_customers/index"
      else
        @merchant_contacts = @list_members
        "merchant_contacts/index"
      end
    end
end
