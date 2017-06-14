class RenameStripePiiIdToStripeFileId < ActiveRecord::Migration
  def change
    rename_column :people, :stripe_pii_id, :stripe_file_id
    remove_index :people, name: :index_people_on_stripe_pii_id if index_exists?(:people, :stripe_file_id, name: "index_people_on_stripe_pii_id")
  end
end
