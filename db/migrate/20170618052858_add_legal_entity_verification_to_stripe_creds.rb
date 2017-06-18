class AddLegalEntityVerificationToStripeCreds < ActiveRecord::Migration
  def change
    add_column :stripe_creds, :legal_entity_verification, :text, after: :fields_needed
    rename_column :stripe_creds, :fields_needed, :account_verification
    change_column :stripe_creds, :account_verification, :text
    remove_column :stripe_creds, :due_by
    remove_column :stripe_creds, :disabled_reason
  end
end
