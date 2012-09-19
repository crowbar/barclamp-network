class CreateConduitFilters < ActiveRecord::Migration
  def change
    create_table :conduit_filters do |t|
      t.string :type
      t.string :attr
      t.string :comparitor
      t.string :value
      t.string :start_value
      t.string :end_value

      t.timestamps
    end
  end
end
