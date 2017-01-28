class AddAuthorUrlToKnowledgeBases < ActiveRecord::Migration
  def change
    add_column :knowledge_bases, :author_url, :string, after: :author
  end
end
