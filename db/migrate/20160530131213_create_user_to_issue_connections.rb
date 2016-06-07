class CreateUserToIssueConnections < ActiveRecord::Migration
  def change
    create_table :user_to_issue_connections do |t|
      t.string 'role'

      t.belongs_to :user, :index => true

      t.belongs_to :issue, :index => true

      t.timestamps :null => false
    end
  end
end
