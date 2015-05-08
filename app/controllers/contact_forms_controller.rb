class ContactFormsController < ApplicationController
  
  def new
  	@contact_form = ContactForm.new
  end

  def create
  	@contact_form = ContactForm.new(contact_forms_params) 
  	@contact_form.request = request 
    respond_to do |format|
      if @contact_form.deliver_now
        format.html do
          redirect_to '/'
        end
        format.json { render nothing: true, status: :ok }
      else
        format.html { render 'new' } 
        format.json { render nothing: true, :status => :unprocessable_entity } 
      end
    end
  end

  private
  
    # Never trust parameters from the scary internet, only allow the white list through.
    def contact_forms_params
      params.require(:contact_form).permit(:name, :email, :message, :organization, :subject)
    end


end
