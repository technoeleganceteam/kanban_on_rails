class Column < ActiveRecord::Base
  include EmptyArrayRemovable
  include IssueToColumnAndSectionConnectionCheckable

  belongs_to :project

  belongs_to :board

  validates :name, :length => { :maximum => Settings.max_string_field_size }, :presence => true

  has_many :issue_to_section_connections, :dependent => :destroy

  def max_order(section)
    section.issue_to_section_connections.where(:column_id => id).order('issue_order DESC').
      first.try(:issue_order).to_i
  end

  def column_issues_for_section(section_id)
    issue_to_section_connections.where(:section_id => section_id.to_i).
      order('issue_order ASC').includes(:issue => :project)
  end
end
