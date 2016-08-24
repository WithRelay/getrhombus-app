class CreateImageRef < ActiveRecord::Migration
  def change
    create_table :image_refs do |t|
      t.references :imageable, polymorphic: true, index: true
      t.references :image, index: true

      t.timestamps
    end
  end
end
