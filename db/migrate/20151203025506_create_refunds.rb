class CreateRefunds < ActiveRecord::Migration
  def change
  	if !( ActiveRecord::Base.connection.table_exists? 'refunds' )
	    create_table :refunds do |t|
	      t.string :uri
	      t.string :time
	      t.string :reason

	      t.timestamps
	    end
	end
  end
end
