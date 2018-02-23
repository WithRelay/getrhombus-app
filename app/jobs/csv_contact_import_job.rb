class CsvContactImportJob < ApplicationJob
  @queue = Rails.env + "_csv_contact_import"

  def perform(merchant, file)
    begin
      path = Paperclip.io_adapters.for(file.attachment).path
      merchant.upload_contact_csv(path)
    rescue StandardError => e
    end
  end

end
  