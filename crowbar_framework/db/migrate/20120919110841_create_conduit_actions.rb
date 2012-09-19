class CreateConduitActions < ActiveRecord::Migration
  def change
    create_table :conduit_actions do |t|
      t.string :type
      t.string :name
      t.string :team_mode

      t.timestamps
    end
  end
end
