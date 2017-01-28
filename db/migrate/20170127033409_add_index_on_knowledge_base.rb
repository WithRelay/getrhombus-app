class AddIndexOnKnowledgeBase < ActiveRecord::Migration
  def change
    add_index :knowledge_bases, :title, name: "normal_title_index", unique: true
    add_index :knowledge_base_categories, :name, unique: true
  end
end
