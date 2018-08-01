class AddEnablePaymentToUsers < ActiveRecord::Migration
  def change
    add_column :users, :enable_payment, :boolean, default: 1
  end
end
