class AddChangelogRelatedFieldsToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :include_issues, :boolean, :default => true, :null => false

    add_column :projects, :include_pull_requests, :boolean, :default => true, :null => false

    add_column :projects, :include_detailed_changes, :boolean, :default => true, :null => false

    add_column :projects, :close_issues, :boolean, :default => false, :null => false

    add_column :projects, :generate_changelogs, :boolean, :default => false, :null => false

    add_column :projects, :emails_for_reports, :text, :array => true, :default => []

    add_column :projects, :write_changelog_to_repository, :boolean, :default => false, :null => false

    add_column :projects, :changelog_locale, :string, :default => 'en', :null => false

    add_column :projects, :changelog_filename, :string, :default => 'CHANGELOG', :null => false
  end
end
