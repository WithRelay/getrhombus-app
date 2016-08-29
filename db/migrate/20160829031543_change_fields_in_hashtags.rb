class ChangeFieldsInHashtags < ActiveRecord::Migration
  def change
    change_column :hashtags, :name, :text
    rename_column :hashtags, :name, :description
    add_column :hashtags, :type, :integer
    rename_column :hashtags, :is_precedent, :charge_amount
    remove_column :hashtags, :not_payment_tag
  end
end
