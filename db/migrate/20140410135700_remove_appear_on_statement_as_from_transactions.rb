class RemoveAppearOnStatementAsFromTransactions < ActiveRecord::Migration
  def change
    remove_column :transactions, :appear_on_statement_as, :string
  end
end
