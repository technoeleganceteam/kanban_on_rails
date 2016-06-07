class CreateSections < ActiveRecord::Migration
  def change
    create_table :sections do |t|
      t.string :name, :null => false

      t.integer :section_order

      t.boolean :include_all, :default => false

      t.string :tags, :array => true, :default => []

      t.belongs_to :project, :index => true

      t.jsonb :meta, :default => {}

      t.timestamps :null => false
    end
  end
end
