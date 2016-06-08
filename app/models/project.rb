class Project < ActiveRecord::Base
  store_accessor :meta, :github_repository_id, :github_name, :github_full_name,
    :is_github_repository, :is_bitbucket_repository, :bitbucket_name, :bitbucket_owner,
    :bitbucket_slug, :bitbucket_full_name, :github_secret_token_for_hook, :bitbucket_secret_token_for_hook,
    :github_url

  has_many :users, :through => :user_to_project_connections

  has_many :user_to_project_connections, :dependent => :destroy

  has_many :issues, :dependent => :destroy

  has_many :sections, :dependent => :destroy

  has_many :columns, :dependent => :destroy

  has_many :issue_to_section_connections

  accepts_nested_attributes_for :columns, :allow_destroy => true, :reject_if => :all_blank

  accepts_nested_attributes_for :sections, :allow_destroy => true, :reject_if => :all_blank

  accepts_nested_attributes_for :issue_to_section_connections

  accepts_nested_attributes_for :issues

  validates :name, :length => { :maximum => Settings.max_string_field_size }, :presence => true

  validates :column_width, :numericality => { :only_integer => true, :greater_than_or_equal_to => 0,
    :less_than_or_equal_to => Settings.max_column_width }

  validate :column_tags_overlapping

  after_save :update_issues

  def parse_issue_params_from_github_webhook(params)
    return if !params[:id].present? || !params[:number].present? || !params[:title].present?

    issue = issues.where("meta ->> 'github_issue_id' = '?'", params[:id].to_i).first

    issue = issues.build.tap { |i| i.github_issue_id = params[:id].to_i } unless issue.present?

    issue.assign_attributes(
      :title => params[:title],
      :body => params[:body],
      :github_issue_comments_count => params[:comments],
      :github_issue_html_url => params[:html_url],
      :tags => params[:labels].to_a.map { |l| l[:name] },
      :github_labels => params[:labels].to_a.map(&:to_a),
      :github_issue_number => params[:number].to_i)

    issue.save!
  end

  def parse_issue_params_from_bitbucket_webhook(params)
    return if !params[:id].present? || !params[:title].present?

    issue = issues.where("meta ->> 'bitbucket_issue_id' = '?'", params[:id]).first

    issue = issues.build.tap { |i| i.github_issue_id = params[:id] } unless issue.present?

    issue.title = params[:title]

    issue.body = params[:content][:raw] if params[:content].present? && params[:content][:raw]

    issue.save!
  end

  private

  def update_issues
    issues.map(&:save)
  end

  def column_tags_overlapping
    if columns.map(&:tags).map{ |t| t.reject(&:empty?) }.combination(2).map{ |t1, t2| t1 & t2 }.flatten.size > 0
      errors.add(:base, (I18n.t '.shared.form_errors.columns.tag'))
    end
  end
end
