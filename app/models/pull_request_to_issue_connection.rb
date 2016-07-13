class PullRequestToIssueConnection < ActiveRecord::Base
  belongs_to :pull_request

  belongs_to :issue
end
