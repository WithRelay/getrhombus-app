class AddAttachmentAttachmentToDocuments < ActiveRecord::Migration
  def self.up
    create_table :documents do |t|
      t.attachment :attachment
      t.references :user, index: true
    end
  end

  def self.down
    remove_attachment :documents, :attachment
  end
end
