class CreateInterfaceMaps < ActiveRecord::Migration
  def change
    create_table :interface_maps do |t|

      t.timestamps
    end
  end
end
