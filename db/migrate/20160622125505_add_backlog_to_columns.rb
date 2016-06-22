class AddBacklogToColumns < ActiveRecord::Migration
  def change
    add_column :columns, :backlog, :boolean, :default => false, :null => false
  end
end
