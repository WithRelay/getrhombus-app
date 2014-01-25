class AddNotesToTransaction < ActiveRecord::Migration
  def change
    add_column :transactions, :notes, :text
    add_column :transactions, :amount_with_taxes, :decimal, :precision => 8, :scale => 2
  end
end
