class CreateChangelogs < ActiveRecord::Migration
  def change
    create_table :changelogs do |t|
      t.belongs_to :project, :index => true

      t.string :tag_name, :null => false

      t.string :last_commit_sha, :null => false

      t.datetime :last_commit_date, :null => false

      t.boolean :handled, :null => false, :default => false

      t.jsonb :meta, :default => {}

      t.timestamps :null => false
    end
  end
end
