class AddSuiteToAddress < ActiveRecord::Migration
  def change
    add_column :addresses, :suite, :string, after: :street_address
    remove_column :users, :suite
  end
end
