class CreateBuses < ActiveRecord::Migration
  def change
    create_table :buses do |t|
      t.integer :order
      t.string :designator

      t.references :bus_map
      t.timestamps
    end
  end
end
