class MessagesController < ApplicationController

	def index
	end
 
	def receive_text_message
		if params[:text] = "Sign UP"
			text = params[:text].downcase.strip
			if text == "sign up" 
				#@text = text
				@message = Message.new
				@message.send_signup_text
			elsif "#{text}" == "pay"

			end
		end
	end


	private
    # Use callbacks to share common setup or constraints between actions.
    def set_message
      @message = Message.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def message_params
      params.require(:message).permit(:text)
    end


end
