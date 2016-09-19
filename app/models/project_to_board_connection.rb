# Class for connecting boards and projects. Need for many to many association.
class ProjectToBoardConnection < ActiveRecord::Base
  belongs_to :project

  belongs_to :board

  after_create :update_issues

  before_destroy :destroy_issue_to_section_connections

  private

  def update_issues
    project.issues.map(&:save)
  end

  def destroy_issue_to_section_connections
    IssueToSectionConnection.where(:board_id => board_id, :project_id => project_id).destroy_all
  end
end
