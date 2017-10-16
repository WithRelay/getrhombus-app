class Api::V1::IntelligenceDataController < Api::V1::BaseController
    
    def index
        input = params.keys.first

        request_hash = {:phone_number => [{"OpenCnamData" => "get_opencnam_info_json_for"},
                                          {"OpenCnamService" => "get_opencnam_info"}],
                        :email => [{"FullContactData" => "get_fullcontact_info_json_for"},
                                   {"FullContactService" => "get_fullcontact_info"}]}

        current = request_hash[input_type(input)].first
        model_class = current.keys[0]
        service_class = current.keys[1]

        data = model_class.constantize.method(current[model_class]).call(input)
        if data
            render json: data
        else
            render json: service_class.constantize.method(current[service_class]).call(input)
        end

    end

    private
        def input_type(input)
            :phone_number if Float(phone_number) rescue :email
        end

end