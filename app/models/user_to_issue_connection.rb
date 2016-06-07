class UserToIssueConnection < ActiveRecord::Base
  belongs_to :user

  belongs_to :issue
end
