class AwayMessage < ActiveRecord::Base
  belongs_to :user
  validates_presence_of :response, if: lambda { self.enabled? }

  def check_office_hours(merchant, user, uid_type, uid, channel)
  	if self.enabled?
  		cur_time = Time.current
  		cur_day = cur_time.strftime("%A")[0..2].downcase
      within_office_hours = cur_time.to_i >= Time.parse(self[cur_day + "_ot"]).to_i  
      within_office_hours = within_office_hours && cur_time.to_i <= Time.parse(self[cur_day + "_ct"]).to_i
  		
      unless within_office_hours
  			text = self.response || "We're away at the moment and will get back to you when we return :)."
  		  Conversation.find_or_create_conversation_for_message_and_send_publish(merchant, user, uid_type, uid, text, channel)
  		end
  	end
  end

end
