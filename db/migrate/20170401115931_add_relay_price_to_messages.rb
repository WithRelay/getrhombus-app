class AddRelayPriceToMessages < ActiveRecord::Migration
  def change
    add_column :messages, :relay_price, :string, after: :message_price
    change_column :messages, :price_unit, :string, after: :message_price
  end
end
