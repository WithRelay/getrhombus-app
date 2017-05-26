class CsvCustomerImportJob < ApplicationJob
  @queue = :csv_customer_import

  def perform(merchant, file)
    begin
      path = Paperclip.io_adapters.for(file.attachment).path
      merchant.upload_customer_csv(path)
    rescue StandardError => e
    end
  end

end
