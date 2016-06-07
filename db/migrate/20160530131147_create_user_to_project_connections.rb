class CreateUserToProjectConnections < ActiveRecord::Migration
  def change
    create_table :user_to_project_connections do |t|
      t.string :role

      t.belongs_to :user, :index => true

      t.belongs_to :project, :index => true

      t.timestamps :null => false
    end
  end
end
