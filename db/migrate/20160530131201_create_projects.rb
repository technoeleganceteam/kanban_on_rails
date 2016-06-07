class CreateProjects < ActiveRecord::Migration
  def change
    create_table :projects do |t|
      t.string :name, :null => false

      t.integer :issues_count, :default => 0, :null => false

      t.integer :column_width, :null => false, :default => 200

      t.integer :column_height, :null => false, :default => 600

      t.jsonb :meta, :default => {}

      t.timestamps :null => false
    end
  end
end
