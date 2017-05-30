class RenameStripePiiIdToStripeFileId < ActiveRecord::Migration
  def change
    rename_column :people, :stripe_pii_id, :stripe_file_id
  end
end
