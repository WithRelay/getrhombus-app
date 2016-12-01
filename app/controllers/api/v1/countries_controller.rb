class Api::V1::CountriesController < API::V1::BaseController

  def get_country_name
    res = []
    begin
      if params[:name]
        CountriesList::COUNTRIES_LIST.each{|h| res << h if h[:name].downcase.include? params[:name].downcase}
      end
      render json:  { "countries" => res }, status: 200
    rescue StandardError => e
      render json: { error: "Unable to find your Country" }, status: 500
    end
  end
end
