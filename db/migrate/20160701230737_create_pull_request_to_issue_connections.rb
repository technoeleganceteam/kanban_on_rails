class CreatePullRequestToIssueConnections < ActiveRecord::Migration
  def change
    create_table :pull_request_to_issue_connections do |t|
      t.belongs_to :pull_request, :index => true

      t.belongs_to :issue, :index => true

      t.timestamps :null => false
    end
  end
end
