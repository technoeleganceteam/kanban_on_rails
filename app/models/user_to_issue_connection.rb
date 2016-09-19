# Class for user to issue connections business logic
class UserToIssueConnection < ActiveRecord::Base
  belongs_to :user

  belongs_to :issue
end
