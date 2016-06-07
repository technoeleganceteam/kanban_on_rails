class CreateIssues < ActiveRecord::Migration
  def change
    create_table :issues do |t|
      t.string :title, :null => false

      t.integer :issue_order, :default => 1, :null => false

      t.text :body

      t.string :tags, :array => true, :default => []

      t.belongs_to :project, :index => true

      t.jsonb :meta, :default => {}

      t.timestamps :null => false
    end
  end
end
