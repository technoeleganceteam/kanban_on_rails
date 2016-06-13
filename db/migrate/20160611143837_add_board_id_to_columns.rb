class AddBoardIdToColumns < ActiveRecord::Migration
  def change
    add_column :columns, :board_id, :integer

    add_index :columns, :board_id
  end
end
