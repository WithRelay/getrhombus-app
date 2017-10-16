class Api::V1::IntelligenceDataController < Api::V1::BaseController
    
    def index
        # Extract querystring from url
        input = params.keys.first

        #TODO: refactor to remove repetitions
        if is_phone_number?(input)
            input_i = OpenCnamData.get_opencnam_info_json_for(input)
            if !input_i.present?
                OpenCnamService.get_opencnam_info(input)
                render json: OpenCnamData.get_opencnam_info_json_for(input)
            else
                render json: input_i
            end
        else
            input_i = FullContactData.get_fullcontact_info_json_for(input)
            if !input_i.present?
                FullContactService.get_fullcontact_info(input)
                render json: FullContactData.get_fullcontact_info_json_for(input)
            else
                render json: input_i
            end
        end
    end

    private
        def is_phone_number?(phone_number)
            true if Float(phone_number) rescue false
        end

end