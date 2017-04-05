class CsvCustomerImportJob < ApplicationJob
  @queue = :csv_customer_import

  def perform(merchant, file)
    begin
      merchant.upload_customer_csv(file)
    rescue StandardError => e
    end
  end

end
