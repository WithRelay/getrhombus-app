class AddAmountRefundedToRefunds < ActiveRecord::Migration
  def change
    add_column :refunds, :amount_refunded, :integer, after: :reason
    change_column :refunds, :transaction_id, :integer, after: :id, index: true
  end
end
