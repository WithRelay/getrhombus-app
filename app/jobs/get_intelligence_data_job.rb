class GetIntelligenceDataJob < ApplicationJob
	@queue = :get_intelligence_data

	def perform(data, type)
		begin
			if type == 'FullContact'
				FullContactService.get_fullcontact_info(data)
			elsif type == 'OpenCNAM'
				OpenCnamService.get_opencnam_info(data)
			end
		rescue StandardError => e
		end
	end

end
