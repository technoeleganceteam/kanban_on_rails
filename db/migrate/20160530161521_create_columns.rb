class CreateColumns < ActiveRecord::Migration
  def change
    create_table :columns do |t|
      t.integer :max_issues_count

      t.integer :column_order

      t.string :tags, :array => true, :default => []

      t.string :name, :null => false

      t.belongs_to :project, :index => true

      t.jsonb :meta, :default => {}

      t.timestamps :null => false
    end
  end
end
