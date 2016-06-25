class Column < ActiveRecord::Base
  include EmptyArrayRemovable

  belongs_to :project

  belongs_to :board

  validates :name, :length => { :maximum => Settings.max_string_field_size }, :presence => true

  validate :empty_tags

  has_many :issue_to_section_connections, :dependent => :destroy

  after_update :update_issues

  def max_order(section)
    section.issue_to_section_connections.where(:column_id => id).order('issue_order DESC').
      first.try(:issue_order).to_i
  end

  def column_issues_for_section(section_id)
    issue_to_section_connections.where(:section_id => section_id.to_i).
      order('issue_order ASC').includes(:issue => :project)
  end

  def build_issue_to_section_connection(section, issue)
    connection = IssueToSectionConnection.where(
      :board_id => board_id, :section_id => section.id, :issue_id => issue.id
    ).first_or_initialize

    connection.issue_order ||= max_order(section) + 1

    connection.assign_attributes(:column_id => id, :project_id => issue.project_id)

    connection.save
  end

  private

  def update_issues
    if tags_changed? || backlog_changed?
      issue_to_section_connections.destroy_all

      board.projects.includes(:issues).map(&:issues).flatten.map(&:save)
    end
  end

  def empty_tags
    errors.add(:base, (I18n.t '.shared.form_errors.columns.tag')) if tags.empty? && !backlog?

    errors.add(:base, (I18n.t '.shared.form_errors.columns.tag')) if !tags.empty? && backlog?
  end
end
