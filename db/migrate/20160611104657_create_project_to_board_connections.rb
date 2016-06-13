class CreateProjectToBoardConnections < ActiveRecord::Migration
  def change
    create_table :project_to_board_connections do |t|
      t.belongs_to :board, :index => true

      t.belongs_to :project, :index => true

      t.timestamps :null => false
    end
  end
end
