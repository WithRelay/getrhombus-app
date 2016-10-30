class ChangeResolutionTypeInConversation < ActiveRecord::Migration
  def change
  	change_column :conversations, :resolution, :string
  end
end
