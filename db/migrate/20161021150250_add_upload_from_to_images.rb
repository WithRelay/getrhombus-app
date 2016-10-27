# adds upload_from field to images
class AddUploadFromToImages < ActiveRecord::Migration
  def up
    add_column :images, :upload_from, :string
  end

  def down
    remove_column :images, :upload_from, :string
  end
end
