class CreateBoards < ActiveRecord::Migration
  def change
    create_table :boards do |t|
      t.boolean :public, :default => false, :null => false

      t.string :tags, :array => true, :default => []

      t.string :name, :null => false

      t.integer :column_width, :null => false, :default => 200

      t.integer :column_height, :null => false, :default => 600

      t.jsonb :meta, :default => {}

      t.timestamps :null => false
    end
  end
end
