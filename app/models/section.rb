class Section < ActiveRecord::Base
  include EmptyArrayRemovable
  include IssueToColumnAndSectionConnectionCheckable

  belongs_to :project

  has_many :issues, :through => :issue_to_section_connections

  has_many :issue_to_section_connections, :dependent => :destroy

  validates :name, :length => { :maximum => Settings.max_string_field_size }, :presence => true

  after_initialize :remove_empty_arrays
end
