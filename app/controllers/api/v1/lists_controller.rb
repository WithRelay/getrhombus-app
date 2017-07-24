class Api::V1::ListsController < API::V1::BaseController

  def index
    begin
      if params[:query]
        list_type = params[:list_type].present? ? " and list_type = #{List.list_types[params[:list_type]]} " : ""
        
        list_mode = ""
        if params[:list_mode] == "list"
          list_mode = " and segment is null "
        elsif params[:list_mode] == 'segment'
          list_mode = " and segment is not null "
        end

        res = current_user.lists.campaign.where("lower(name) like ? " + list_mode + list_type , "%#{params[:query].downcase}%")
      else
        res = current_user.lists.campaign
      end
      render json: { "lists" => res }, status: 200
    rescue StandardError => e
      render json: { error: "Unable to find your lists" }, status: 500
    end
  end

  def check_list_name
    list_name = list_params[:name] || segment_params[:segment_name]
    list = current_user.lists.campaign.find_by_name(list_name)
    render json: { valid: list.nil? }
  end

  # Handles creation of a list via Ajax
  def create
    begin
      if list_params[:list_category] == 'list'
        list = current_user.lists.build(name: list_params[:name], list_type: list_params[:list_type], campaign_type: List.campaign_types[:campaign],
                                        channel: list_params[:list_channel], origin: List.origins[:merchant])

        selected_mc_ids = list_params[:selected_users].split(",")
        mc_type = list_params[:list_type] == 'contact' ? 'MerchantContact' : 'MerchantCustomer'
        
        selected_mc_ids.each do |mc_id|
          list.user_lists.build(customer_contact_id: mc_id, customer_contact_type: mc_type)
        end

        # list also save associated record
        if list.save
          render json: { notice: 'List saved successfully', redirect_url: user_lists_url(current_user) }
        else
          render json: { error: list.errors.full_messages.to_json }, status: 500
        end
      else
        @list = save_list
        if @list.errors.full_messages.blank?
          render json: { notice: "Segment saved" }, status: 200
        else
          render json: { error: @list.errors.full_messages }, status: 500
        end
      end
    rescue StandardError => e
      render json: { error: "Unable to create segment" }, status: 500
    end
  end

  def update
    # handle both static list and segments
    list = current_user.lists.find_by(id: params[:id])
    text = list.segment.present? ? 'Segment' : 'List'
    if list.present? && list.update_attributes(name: params[:list][:name])
      msg = { notice: "#{text} was successfully updated" }
    else
      msg = { error: list.nil? ? "#{text} does not exists" : list.errors.full_messages }
      status = 500
    end

    if list.segment.present?
      render json: msg, status: status || 200
    else
      redirect_to user_lists_path(current_user), flash: msg
    end
  end

  private
    # create segment
    # @param name The name of the list
    # @param user_id The user_id
    # @param segment a text field that stores segment data
    # default is nil (i.e. list)
    def save_list
      @filter_params = segment_params
      List.create(name: @filter_params[:segment_name], list_type: @filter_params[:list_type], origin: List.origins[:merchant],
                  channel: @filter_params[:list_channel], user_id: current_user.id, segment: get_segment_data_hash, 
                  campaign_type: List.campaign_types[:campaign])
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
end
