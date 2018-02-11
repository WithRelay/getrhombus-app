class Api::V1::MerchantContactsController < Api::V1::BaseController

  def index
    begin
      q = "%#{params[:query].downcase}%"
      if params[:channel] == 'messenger'
        str =  "(select merchant_contacts.id, coalesce(NULLIF(card_name, ''), email) as title, 
                'Messenger Contact' as description from merchant_contacts
                inner join fb_creds on fb_creds.page_specific_id = merchant_contacts.uid
                where merchant_id = #{current_user.id} and uid_type = 'fb_page' and is_customer = false and 
                (lower(name) like '#{q}' or lower(email) like '#{q}'))"
      elsif params[:channel] == 'sms'
        str = "(select merchant_contacts.id, uid as title, 'SMS Contact' as description
                from merchant_contacts where merchant_id = #{current_user.id} and is_customer = false 
                and uid_type = 'phone_number' and uid like '#{q}')"
      end
        
      results = User.find_by_sql str
      render json: { data: results }
    rescue StandardError => e
      render json: { error: "Unable to find your contacts" }, status: 500
    end 
    
  end

  def contact_csv
    begin
      status = 500
      response = "Your CSV file has been uploaded. This might take a while to complete."
      doc = current_user.documents.create(attachment: params['csv'])
      puts doc.errors.inspect
      puts doc.errors.full_messages.inspect
      if doc.errors.full_messages.blank?
        CsvContactImportJob.perform_later(current_user, doc)
        status = 200
      else
        response = doc.errors.full_messages
      end
    rescue StandardError => exception
      response = 'Unable to upload customer csv'
      ExceptionNotifier.notify_exception(exception, env: request.env, data: { message: "In v1 merchant_contacts contact_csv_upload", env: Rails.env })      
    end

    render json: { response: response }, status: status
  end

end