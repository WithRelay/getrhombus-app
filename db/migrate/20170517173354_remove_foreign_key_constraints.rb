class RemoveForeignKeyConstraints < ActiveRecord::Migration
  def change   
    foreign_keys(:alerts).each do |k|
      remove_foreign_key :alerts, name: :k
    end

    foreign_keys(:invoices).each do |k|
      remove_foreign_key :invoices, name: :k
    end

    foreign_keys(:subscriptions).each do |k|
      remove_foreign_key :subscriptions, name: :k
    end

    foreign_keys(:transactions).each do |k|
      remove_foreign_key :transactions, name: :k
    end
  end
end
