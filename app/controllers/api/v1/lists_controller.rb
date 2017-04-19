class Api::V1::ListsController < API::V1::BaseController
  include CustomerSegmentQueries

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
    list_name = list_params[:name] || segment_params[:segment_name]
    list = current_user.lists.find_by_name(list_name)
    render json: { valid: list.nil? }
  end

  # Handles creation of a list via Ajax
  def create
    begin
      if list_params[:list_category] == 'list'
        list = current_user.lists.build(name: list_params[:name], list_type: list_params[:list_type])
        selected_users_id = list_params[:selected_users].split(",")
        selected_users_id.each { |user_id| list.user_lists.build(user_id: user_id) }
        # list also save associated record
        message = if list.save
                    { notice: 'List saved successfully', status: 200, redirect_url: list_url(current_user, list) }
                  else
                    { error: list.errors.full_messages.to_json, status: 404 }
                  end
        render json: message
      else
        segment_query = get_segment_query
        list = save_list(name: segment_params[:segment_name], user_id: current_user.id,
                          segment: segment_query)
        list_errors = get_list_errors(list)
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
    segment = current_user.lists.where.not(segment: nil).find_by(id: params[:id])
    message = if segment.present? && segment.update_attributes(name: params[:name])
                { status: 200, notice: 'List was successfully updated.', name: params[:name] }
              else
                { status: 400, error: segment.errors.full_messages }
              end
    render json: message
  end

  def merchant_segment
    user_segments = if current_user.present? && current_user.is_merchant?
                      segment_list = current_user.user_segments
                      params[:list_type].present? ? segment_list.contact : segment_list.customer
                    else
                      []
                    end
    render json: user_segments
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
      return l
    end

    def list_params
      params.require(:lists).permit(:selected_users, :list_category, :name, :list_type)
    end

    def segment_params
      params.require(:lists).permit(:segment_type, :list_category, :segment_num_days,
                                    :segment_filter, :amt_filter, :amt_1, :amt_2, :segment_name)
    end

    # Get the SQL query for the segment
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
