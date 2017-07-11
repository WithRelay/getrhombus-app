class ChangeUrlInKnowledgeBases < ActiveRecord::Migration
  def change
    rename_column :knowledge_bases, :url, :slug
    change_column :knowledge_bases, :slug, :string, unique: true
  end
end
