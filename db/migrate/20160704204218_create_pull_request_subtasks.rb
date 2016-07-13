class CreatePullRequestSubtasks < ActiveRecord::Migration
  def change
    create_table :pull_request_subtasks do |t|
      t.belongs_to :pull_request, :index => true

      t.belongs_to :changelog, :index => true

      t.string :story_points

      t.text :description, :null => false

      t.string :task_type

      t.jsonb :meta, :default => {}

      t.timestamps :null => false
    end
  end
end
