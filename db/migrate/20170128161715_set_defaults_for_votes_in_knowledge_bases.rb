class SetDefaultsForVotesInKnowledgeBases < ActiveRecord::Migration
  def change
  	change_column :knowledge_bases, :upvotes, :integer, default: 0
  	change_column :knowledge_bases, :downvotes, :integer, default: 0
  end
end
