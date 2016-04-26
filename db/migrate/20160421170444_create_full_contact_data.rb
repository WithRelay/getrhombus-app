class CreateFullContactData < ActiveRecord::Migration
  def change
    create_table :full_contact_data do |t|
      t.string :likelihood, default: nil
      t.string :photo_type_id, default: nil
      t.string :photo_url, default: nil
      t.string :given_name, default: nil
      t.string :family_name, default: nil
      t.string :org_name, default: nil
      t.string :org_title, default: nil
      t.string :age_range, default: nil
      t.string :gender, default: nil
      t.string :city, default: nil
      t.string :country, default: nil
      t.string :website_url, default: nil
      t.string :email, null: false, default: "", index: { unique: true }

      t.timestamps
    end

    create_table :full_contact_social_data do |t|
      t.string :bio, default: nil
      t.string :followers, default: nil
      t.string :type_id, default: nil
      t.string :url, default: nil
      t.string :following, default: nil
      t.integer :full_contact_data_id
      
      t.timestamps
    end

    add_index :full_contact_social_data, :full_contact_data_id
  end
end
