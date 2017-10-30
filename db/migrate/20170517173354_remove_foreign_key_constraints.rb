class RemoveForeignKeyConstraints < ActiveRecord::Migration
  def change   
    foreign_keys(:alerts).each do |k|
      remove_foreign_key :alerts, name: k.options[:name]
    end

    foreign_keys(:invoices).each do |k|
      remove_foreign_key :invoices, name: k.options[:name]
    end

    foreign_keys(:subscriptions).each do |k|
      remove_foreign_key :subscriptions, name: k.options[:name]
    end

    foreign_keys(:transactions).each do |k|
      remove_foreign_key :transactions, name: k.options[:name]
    end
  end
end
