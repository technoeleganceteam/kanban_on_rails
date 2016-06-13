class AddBoardIdToIssueToSectionConnections < ActiveRecord::Migration
  def change
    add_column :issue_to_section_connections, :board_id, :integer

    add_index :issue_to_section_connections, :board_id
  end
end
