class CreateUserToBoardConnections < ActiveRecord::Migration
  def change
    create_table :user_to_board_connections do |t|
      t.string :role

      t.belongs_to :board, :index => true

      t.belongs_to :user, :index => true

      t.timestamps :null => false
    end
  end
end
