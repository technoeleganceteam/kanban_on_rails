module IssueToColumnAndSectionConnectionCheckable
  extend ActiveSupport::Concern

  included do
    after_save :update_issue_to_section_connections
  end

  private

  def update_issue_to_section_connections
    issue_to_section_connections.includes(:issue => :project).each do |connection|
      next if self.class.name == 'Section' && include_all?

      next unless connection.issue.present?

      connection.destroy if (connection.issue.tags.to_a & tags.to_a).empty?
    end

    project.issues.includes(:project).map(&:assign_issue_to_section_connections) if project.present?
  end
end
