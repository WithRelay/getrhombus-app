class AddFullTextIndex < ActiveRecord::Migration
  def change
    add_index :knowledge_bases, [:title, :raw_content], :type => :fulltext
  end
end
