class CreateRouters < ActiveRecord::Migration
  def change
    create_table :routers do |t|
      t.integer :pref
      t.references :network

      t.timestamps
    end
  end
end
