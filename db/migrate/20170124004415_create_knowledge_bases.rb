class CreateKnowledgeBases < ActiveRecord::Migration
  def change
    create_table :knowledge_bases do |t|
      t.string :title, unique: true
      t.string :author
      t.integer :upvotes
      t.integer :downvotes
      t.string :url, unique: true
      t.text :raw_content
      t.integer :knowledge_base_category_id

      t.timestamps null: false
    end
  end
end
