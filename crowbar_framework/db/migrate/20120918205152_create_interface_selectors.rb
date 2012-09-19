class CreateInterfaceSelectors < ActiveRecord::Migration
  def change
    create_table :interface_selectors do |t|
      t.string :type
      t.string :comparitor
      t.string :value
      t.string :start_value
      t.string :end_value

      t.timestamps
    end
  end
end
