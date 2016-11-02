class ChangeColumnUploadedFrom < ActiveRecord::Migration
  def up
    rename_column :images, :upload_from, :uploaded_as
    change_column :images, :uploaded_as, :integer
  end

  def down
    rename_column :images, :uploaded_as, :upload_from
    change_column :images, :upload_from, :string
  end
end
