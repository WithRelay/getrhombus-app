class AddDefaultValueForApplicationFee < ActiveRecord::Migration
  def change
    change_column :invoices, :application_fee, :integer, :default => 0
  end
end
