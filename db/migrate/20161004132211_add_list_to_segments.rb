class AddListToSegments < ActiveRecord::Migration
  def change
  	add_reference :segments, :list, index: true
  end
end
