class PullRequestSubtask < ActiveRecord::Base
  belongs_to :pull_request

  validates :description, :length => { :maximum => Settings.max_text_field_size }, :presence => true
end
