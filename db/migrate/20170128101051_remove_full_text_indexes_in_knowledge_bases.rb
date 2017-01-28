class RemoveFullTextIndexesInKnowledgeBases < ActiveRecord::Migration
  def change
  	remove_index :knowledge_bases, :raw_content
  	remove_index :knowledge_bases, :title
  	remove_index :knowledge_bases, name: 'normal_title_index'
  end
end
