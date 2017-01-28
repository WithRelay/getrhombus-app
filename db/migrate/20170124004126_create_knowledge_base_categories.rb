class CreateKnowledgeBaseCategories < ActiveRecord::Migration
  def change
    create_table :knowledge_base_categories do |t|
      t.string :name, unique: true

      t.timestamps null: false
    end
  end
end
  