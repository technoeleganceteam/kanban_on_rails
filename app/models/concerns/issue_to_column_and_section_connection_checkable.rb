module IssueToColumnAndSectionConnectionCheckable
  extend ActiveSupport::Concern

  included do
    after_save :update_issue_to_section_connections
  end

  private

  def update_issue_to_section_connections
    issue_to_section_connections.includes(:issue => :project).each do |connection|
      connection.destroy if need_to_destroy?(connection)
    end
  end

  def need_to_destroy?(connection)
    !section_and_include_all? && connection.issue.present? && (connection.issue.tags.to_a & tags.to_a).empty?
  end

  def section_and_include_all?
    self.class.name == 'Section' && include_all?
  end
end
