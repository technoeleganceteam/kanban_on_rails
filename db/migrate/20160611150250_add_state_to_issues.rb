class AddStateToIssues < ActiveRecord::Migration
  def change
    add_column :issues, :state, :string, :default => 'open', :null => false

    add_index :issues, :state
  end
end
