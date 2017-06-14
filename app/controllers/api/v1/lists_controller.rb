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
    list_name = list_params[:name] || segment_params[:segment_name]
    list = current_user.lists.find_by_name(list_name)
    render json: { valid: list.nil? }
  end

  # Handles creation of a list via Ajax
  def create
    begin
      if list_params[:list_category] == 'list'
        list = current_user.lists.build(name: list_params[:name], list_type: list_params[:list_type], 
                                        channel: list_params[:list_channel], origin: 0)

        selected_mc_ids = list_params[:selected_users].split(",")
        mc_type = list_params[:list_type] == 'contact' ? 'MerchantContact' : 'MerchantCustomer'
        
        selected_mc_ids.each do |mc_id|
          list.user_lists.build(customer_contact_id: mc_id, customer_contact_type: mc_type)
        end

        # list also save associated record
        if list.save
          message = { notice: 'List saved successfully', status: 200, redirect_url: list_url(current_user, list) }
        else
          message = { error: list.errors.full_messages.to_json, status: 404 }
        end
        render json: message
      else
        @list = save_list
        list_errors = get_list_errors
        if list_errors.blank?
           render json: { "list" => @list }, status: 200
        else
          render json: { "list_error" => list_errors.to_json }, status: 400
        end
      end
    rescue StandardError => e
      render json: { error: "Unable to create segment" }, status: 500
    end
  end

  def update
    # handle both static list and segments
    list = current_user.lists.find_by(id: params[:id])
    if list.present? && list.update_attributes(name: params[:name])
      message = { status: 200, notice: 'List was successfully updated.', name: params[:name] }
    else
      error = list.nil? ? 'List does not exists' : list.errors.full_messages
      message = { status: 400, error: error }
    end

    render json: message
  end

  # this is used by static list only for now. Segments don't use ajax to delete.
  def destroy
    if @list.campaign_lists.present?
      msg = 'Unable to delete a list that has been attached to a campaign'
    else
     @list.destroy 
     msg = @list.destroyed? ? 'List has been deleted' : 'Unable to delete list'
    end

    render json: { notice: msg }
  end

  private
    # create segment
    # @param name The name of the list
    # @param user_id The user_id
    # @param segment a text field that stores segment data
    # default is nil (i.e. list)
    def save_list
      @filter_params = segment_params
      List.create(name: @filter_params[:segment_name], list_type: @filter_params[:list_type], origin: 0,
                  channel: @filter_params[:list_channel], user_id: current_user.id, segment: get_segment_data_hash)
    end

    def list_params
      params.require(:lists).permit(:selected_users, :list_category, :name, :list_type, :list_channel).tap do |p|
        p[:list_channel] = p[:list_channel].present? ? p[:list_channel] : nil
      end
    end

    def segment_params
      params.require(:lists).permit(:list_type, :segment_name, :segment_filter, :segment_type, :segment_num_days, 
                                    :list_channel, :additional_segment_type, :amt_filter, :amt_1, :amt_2).tap do |p|
        p[:list_channel] = p[:list_channel].present? ? p[:list_channel] : nil
        unless p[:amt_1].present?
          p[:additional_segment_type] = p[:additional_segment_type].present? ? p[:additional_segment_type] : nil
          p[:amt_filter] = p[:amt_filter].present? ? p[:amt_filter] : nil
        end
      end
    end

    def get_segment_data_hash
      { 
        base_query: @filter_params[:segment_type], base_filter: @filter_params[:segment_filter], base_val: @filter_params[:segment_num_days],
        additional_query: @filter_params[:additional_segment_type], addition_filter: @filter_params[:amt_filter],
        addition_val: @filter_params[:amt_1]
       }
    end

    # Returns an array of errors that were generated in the process of creating the list
    def get_list_errors
      list_errors = Array.new
      list_errors.push(@list.errors.full_messages) if @list.errors.present?
      list_errors
    end
end
