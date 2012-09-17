class CreateBusMaps < ActiveRecord::Migration
  def change
    create_table :bus_maps do |t|
      t.string :pattern

      t.references :interface_map
      t.timestamps
    end
  end
end
