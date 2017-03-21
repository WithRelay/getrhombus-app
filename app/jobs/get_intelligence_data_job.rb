class GetIntelligenceDataJob < ApplicationJob
	@queue = :get_intelligence_data

	def self.perform(data, type)
		if type == 'FullContact'
			FullContactService.get_fullcontact_info(data)
		elsif type == 'OpenCNAM'
			OpenCnamService.get_opencnam_info(data)
		end
	end

end
