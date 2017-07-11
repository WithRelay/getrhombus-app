class ChangeImageInKnowledgeBaseCategoy < ActiveRecord::Migration
  def change
    rename_column :knowledge_base_categories, :image, :image_name
  end
end
