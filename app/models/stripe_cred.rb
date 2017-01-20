class StripeCred < ActiveRecord::Base

  # for saving array in fields_needed column http://api.rubyonrails.org/classes/ActiveRecord/Base.html#M001799
  serialize :fields_needed
  belongs_to :user
  enum uid_type: [ :managed, :standalone ]


  # saves merchant info from stripe

  def self.from_omniauth(auth, id)
    begin
       where(user_id: id).first_or_initialize.tap do |row|
          row.uid = auth.uid
          row.uid_type = 1
          row.secret = auth.credentials.token
          row.publishable_key = auth.info.stripe_publishable_key
          row.stripe_scope = auth.info.scope
          row.stripe_livemode = auth.info.livemode
          row.save
       end
      true
    rescue StandardError => e
      false
    end
  end

end


