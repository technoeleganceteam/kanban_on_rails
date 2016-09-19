# Class for pull request subtasks business logic
class PullRequestSubtask < ActiveRecord::Base
  belongs_to :pull_request

  validates :description, :length => { :maximum => Settings.max_text_field_size }, :presence => true

  def info_for_report
    "#{ "[#{ task_type }]" if task_type.present? }" \
      "#{ "[#{ story_points }] " if story_points.present? }#{ description }\n"
  end
end
