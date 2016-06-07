class UserToProjectConnection < ActiveRecord::Base
  belongs_to :project

  belongs_to :user

  validates :role, :presence => true, :inclusion => ['owner', 'member', 'manager']
end
