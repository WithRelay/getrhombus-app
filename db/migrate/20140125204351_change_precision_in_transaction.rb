class ChangePrecisionInTransaction < ActiveRecord::Migration
  def change
  	change_column :transactions, :amount, :decimal, :precision => 8, :scale => 2
    change_column :transactions, :amount_less_fees, :decimal, :precision => 8, :scale => 2
    change_column :messages, :message_price, :string
  end
end
