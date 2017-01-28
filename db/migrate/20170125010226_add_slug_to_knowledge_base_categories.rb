class AddSlugToKnowledgeBaseCategories < ActiveRecord::Migration
  def change
    add_column :knowledge_base_categories, :slug, :string
    add_index :knowledge_base_categories, :slug, unique: true
  end
end
