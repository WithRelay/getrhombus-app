class AddNotPaymentTagToHashtag < ActiveRecord::Migration
  def change
    add_column :hashtags, :not_payment_tag, :boolean
    rename_column :hashtags, :isPrecedent, :is_precedent
  end
end
