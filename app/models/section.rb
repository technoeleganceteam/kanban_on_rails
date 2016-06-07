class Section < ActiveRecord::Base
  include EmptyArrayRemovable
  include IssueToColumnAndSectionConnectionCheckable

  belongs_to :project

  has_many :issues, :through => :issue_to_section_connections

  has_many :issue_to_section_connections, :dependent => :destroy

  validates :name, :length => { :maximum => Settings.max_string_field_size }, :presence => true

  after_initialize :remove_empty_arrays

  private

  def remove_empty_arrays
    attributes.keys.each do |attribute|
      if self[attribute].is_a?(Array) && self[attribute].present?
        self[attribute] = self[attribute].reject(&:blank?)
      end
    end
  end
end
