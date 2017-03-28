class ChangeThurCtColumnInAwayMessages < ActiveRecord::Migration
  def change
  	rename_column :away_messages, :thur_ot, :thu_ot
  	rename_column :away_messages, :thur_ct, :thu_ct
  	change_column :away_messages, :enabled, :boolean, default: false
  end
end
