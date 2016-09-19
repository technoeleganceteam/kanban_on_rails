# Class for boards business logic
class Board < ActiveRecord::Base
  has_many :users, :through => :user_to_board_connections

  has_many :user_to_board_connections, :dependent => :destroy

  has_many :issues, :dependent => :destroy, :through => :issue_to_section_connections

  has_many :issue_to_section_connections, :dependent => :destroy

  has_many :sections, :dependent => :destroy

  has_many :columns, :dependent => :destroy

  has_many :projects, :through => :project_to_board_connections

  has_many :project_to_board_connections, :dependent => :destroy

  accepts_nested_attributes_for :columns, :allow_destroy => true, :reject_if => :all_blank

  accepts_nested_attributes_for :sections, :allow_destroy => true, :reject_if => :all_blank

  accepts_nested_attributes_for :issue_to_section_connections

  accepts_nested_attributes_for :issues

  validates :name, :length => { :maximum => Settings.max_string_field_size }, :presence => true

  validates :column_width, :numericality => { :only_integer => true, :greater_than_or_equal_to => 0,
    :less_than_or_equal_to => Settings.max_column_width }

  validates :column_height, :numericality => { :only_integer => true, :greater_than_or_equal_to => 0,
    :less_than_or_equal_to => Settings.max_column_height }

  validate :column_tags_overlapping

  after_update :update_issue_to_section_connections

  after_create :update_issues

  def issue_to_section_connections_from_params(params = {})
    connections = issue_to_section_connections.includes(:issue => :project)

    [:column_id, :section_id].each do |field|
      value = params[field]

      connections = connections.where(field => value) if value.present?
    end

    connections
  end

  private

  def update_issues
    projects.map(&:issues).flatten.map(&:save)
  end

  def update_issue_to_section_connections
    issue_to_section_connections.where.not(:project_id => project_ids).destroy_all
  end

  def column_tags_overlapping
    tags_combinations = columns.map(&:tags).map { |tag| tag.reject(&:empty?) }.combination(2)

    unless tags_combinations.map { |first_tag, second_tag| first_tag & second_tag }.flatten.empty?
      errors.add(:base, (I18n.t '.shared.form_errors.columns.tag'))
    end
  end
end
