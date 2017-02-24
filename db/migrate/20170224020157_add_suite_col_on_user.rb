class AddSuiteColOnUser < ActiveRecord::Migration
  def change
    add_column :users, :suite, :string, after: 'street_address'
  end
end
