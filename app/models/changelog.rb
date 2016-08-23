class Changelog < ActiveRecord::Base
  belongs_to :project

  has_many :pull_requests, :dependent => :destroy

  has_many :issues

  has_many :pull_request_subtasks

  validates :tag_name, :last_commit_sha, :length => { :maximum => Settings.max_string_field_size },
    :presence => true

  validates :last_commit_date, :presence => true

  delegate :emails_for_reports, :to => :project, :prefix => true

  def close_issues
    pull_requests.map(&:issues).flatten.uniq.each do |issue|
      next unless issue.provider_id?

      issue.update_attributes(:state => 'closed')

      issue.send("#{ issue.provider }_update_issue", project.send("#{ project.provider }_client_for_changelogs"))
    end
  end

  def sorted_pull_request_subtasks
    pull_request_subtasks.sort_by { |item| Settings.story_point_values.index(item) }
  end
end
