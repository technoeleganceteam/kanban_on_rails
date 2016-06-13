class AddBoardIdToSections < ActiveRecord::Migration
  def change
    add_column :sections, :board_id, :integer

    add_index :sections, :board_id
  end
end
