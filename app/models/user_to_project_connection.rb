# Class provide user to project connections business logic
class UserToProjectConnection < ActiveRecord::Base
  belongs_to :project

  belongs_to :user

  validates :role, :presence => true, :inclusion => %w(owner member manager)
end
