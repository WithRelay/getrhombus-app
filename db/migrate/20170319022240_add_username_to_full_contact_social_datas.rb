class AddUsernameToFullContactSocialDatas < ActiveRecord::Migration
  def change
    add_column :full_contact_social_data, :username, :string, after: :id
  end
end
