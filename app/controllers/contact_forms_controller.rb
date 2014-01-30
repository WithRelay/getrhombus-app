class ContactFormsController < ApplicationController
  def new
  	@contact_form = ContactForm.new
  end

  def create
  	begin
  		@contact_form = ContactForm.new(params[:contact_form]) 
  		@contact_form.request = request 
      respond_to do |format|
  		  if @contact_form.deliver 
  			   format.html { redirect_to "/contactus", notice: 'Your message has been sent. We will contact you shortly!' }
   		  else 
  			   format.html { render action: 'new' }
  		  end 
      end
  	rescue ScriptError 
  		flash[:error] = 'Sorry, this message appears to be spam and was not delivered.'
  	end
  end
end
