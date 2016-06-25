class Section < ActiveRecord::Base
  include EmptyArrayRemovable

  belongs_to :project

  belongs_to :board

  has_many :issues, :through => :issue_to_section_connections

  has_many :issue_to_section_connections, :dependent => :destroy

  validates :name, :length => { :maximum => Settings.max_string_field_size }, :presence => true

  before_update :update_issues

  private

  def update_issues
    if tags_changed? || include_all_changed?
      issue_to_section_connections.destroy_all

      board.projects.map(&:issues).flatten.map(&:save)
    end
  end
end
