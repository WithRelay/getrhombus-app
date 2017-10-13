class Api::V1::IntelligenceDataController < Api::V1::BaseController
    
    def index
        render json: {'GET':'Data'}
    end

end