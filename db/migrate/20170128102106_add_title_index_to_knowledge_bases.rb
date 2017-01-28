class AddTitleIndexToKnowledgeBases < ActiveRecord::Migration
  def change
  	add_index :knowledge_bases, :title, unique: true
  end
end
