class Api::V1::ListsController < API::V1::BaseController
 
  def index
    begin
      if params[:query]
        res = List.where("lower(name) like ? and user_id = ?", "%#{params[:query].downcase}%", current_user.id)
      else
        res = List.where(user_id: current_user.id)
      end

      render json: { "lists" => res }, status: 200
    rescue StandardError => e
      render json: { error: "Unable to find your lists" }, status: 500
    end
  end


  # Handles creation of a list via Ajax
  def create
    begin
      name = params[:list_name]
      if params[:list_type] == 'list'
        @list = save_list(name:name, user_id:current_user.id)
        user_list = params[:selected_users].split(",")
        list_errors = Array.new # Gather list errors
        # If there were any errors with saving the list 
        # add them to the array
        if !@list.errors.empty?
          list_errors.push(@list.errors.full_messages)
        end
        # Create user_lists and and errors as well.
        user_list.each do |u|
          u = UserList.new(list_id:@list.id, user_id:u)
          list_errors.push(u.errors.full_messages) if !u.save
        end
          # If there are errors, show the errors
          if !list_errors.empty?
            puts "Errors occured: #{list_errors}"
            render json: {
               "list_error" => list_errors.to_json,
            }, status: 400
          # no errors, show the created list and users
          else
            render json: {
              "list" => @list,
              "list_users" => user_list,
            }, status: 200
          end
      else
        @list = save_list(name:name, user_id:current_user.id, segment:true)
        segment.new(list_id:@list.id, query:params[:segment_query])
      end
    rescue StandardError => e
      puts e
      render json: { 
        error: e.message,
         }, status: 500
    end
  end

  private
    # Default method for creating lists
    # @param name The name of the list
    # @param user_id The user_id
    # @param segment A boolean indicating if this list is a segment
    # default is false (i.e. list)
    def save_list(name:, user_id:, segment:false)
      l = List.new(name:name, user_id:user_id, segment:segment)
      l.save
      return l
    end

end
