class Api::V1::ListsController < API::V1::BaseController

  def index
    begin
      if params[:query]
        list_type = ""
        if params[:type] == "list"
          list_type = "and segment is null"
        elsif params[:type] == 'segment'
          list_type = "and segment is not null"
        end
        if params[:query].to_i != 0
          res = current_user.lists.where( { id: params[:query] })
        else
          res = current_user.lists.where("lower(name) like ? " + list_type , "%#{params[:query].downcase}%")
        end
      else
        res = current_user.lists
      end
      render json: { "lists" => res }, status: 200
    rescue StandardError => e
      render json: { error: "Unable to find your lists" }, status: 500
    end
  end

  def check_list_name
    list = current_user.lists.find_by_name(list_params[:name])
    render json: { valid: list.nil? }
  end

  # Handles creation of a list via Ajax
  def create
    begin
      if list_params[:list_type] == 'list'
        list = current_user.lists.build(name: list_params[:name])
        selected_users_id = list_params[:selected_users].split(",")
        selected_users_id.each { |user_id| list.user_lists.build(user_id: user_id) }
        # list also save associated record
        message = if list.save
                    { notice: 'List saved successfully', status: 200 }
                  else
                    { error: list.errors.full_messages.to_json, status: 404 }
                  end
        render json: message
      else
        params[:current_time] = Time.current
        name = params[:segment_name]
        segment_query = get_segment_query(params)
        print "Segment query is: #{segment_query}"
        @list = save_list(name:name,
                          user_id:current_user.id,
                          segment:segment_query)
        list_errors = get_list_errors(@list)
        if list_errors.blank?
           render json: {
              "list" => @list,
            }, status: 200
        else
          render json: {
               "list_error" => list_errors.to_json,
            }, status: 400
        end
      end
    rescue StandardError => e
      puts e
      render json: {
        error: e.message,
         }, status: 500
    end
  end


  def update

  end

  private
    # Default method for creating lists
    # @param name The name of the list
    # @param user_id The user_id
    # @param segment A boolean indicating if this list is a segment
    # default is nil (i.e. list)
    def save_list(name:, user_id:, segment:nil)
      l = List.new(name:name, user_id:user_id, segment:segment)
      l.save
      print "List created is: #{l}"
      return l
    end

    def list_params
      params.require(:lists).permit(:selected_users, :list_type, :name)
    end

    # Get the SQL query for the segment
    def get_segment_query(params)
      # Pass the current time in the user's time zone
      params[:current_time] = Time.current
      print "Segment type is: #{params[:segment_type]} \n"
      if params[:segment_type] == "new_customers"
         DashboardMerchantQueries.get_new_customers(params)
      elsif params[:segment_type] == "active_customers"
        DashboardMerchantQueries.get_active_customers(params)
      elsif params[:segment_type] == "inactive_customers"
        DashboardMerchantQueries.get_inactive_customers(params)
      elsif params[:segment_type] == "all_contacts"
         DashboardMerchantQueries.get_all_segment(params)
      elsif params[:segment_type] == "all_customers"
        DashboardMerchantQueries.get_all_segment(params)
      elsif params[:segment_type] == "contacts_with_account"
        DashboardMerchantQueries.get_contacts_with_account
      elsif params[:segment_type] == "contacts_without_account"
        DashboardMerchantQueries.get_contacts_without_account
      elsif params[:segment_type] == "last_purchase"
        DashboardMerchantQueries.get_last_transactions(params)
      elsif params[:segment_type] == "last_msg_received"
        DashboardMerchantQueries.get_last_msg_received(params)
      elsif params[:segment_type] == "last_msg_sent"
        DashboardMerchantQueries.get_last_msg_sent(params)
      end
    end

    # Returns an array of errors that were generated in
    # the process of creating the list
    # @param list_obj A list object
    def get_list_errors(list_obj)
      list_errors = Array.new
      if !list_obj.errors.blank?
        list_errors.push(@list.errors.full_messages)
      end
      return list_errors
    end
end
