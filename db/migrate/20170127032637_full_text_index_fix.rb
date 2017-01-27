class FullTextIndexFix < ActiveRecord::Migration
  def change
    remove_index :knowledge_bases, [:title, :raw_content]
    add_index :knowledge_bases, :title, :type => :fulltext
    add_index :knowledge_bases, :raw_content, :type => :fulltext
  end
end
