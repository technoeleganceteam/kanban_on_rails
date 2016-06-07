class CreateIssueToSectionConnections < ActiveRecord::Migration
  def change
    create_table :issue_to_section_connections do |t|
      t.integer :issue_order

      t.belongs_to :column, :index => true

      t.belongs_to :project, :index => true

      t.belongs_to :issue, :index => true

      t.belongs_to :section, :index => true

      t.timestamps :null => false
    end
  end
end
