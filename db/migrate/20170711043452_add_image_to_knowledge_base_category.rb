class AddImageToKnowledgeBaseCategory < ActiveRecord::Migration
  def change
    add_column :knowledge_base_categories, :image, :string
  end
end
