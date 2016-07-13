class CreatePullRequests < ActiveRecord::Migration
  def change
    create_table :pull_requests do |t|
      t.belongs_to :project, :index => true

      t.belongs_to :changelog, :index => true

      t.string :title, :null => false

      t.datetime :merged_at, :null => false

      t.text :body

      t.string :id_from_provider, :null => false

      t.string :created_by

      t.jsonb :meta, :default => {}

      t.timestamps :null => false
    end
  end
end
