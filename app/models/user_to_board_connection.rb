# Class for user to board connections business logic
class UserToBoardConnection < ActiveRecord::Base
  belongs_to :user

  belongs_to :board

  validates :role, :presence => true, :inclusion => %w(owner member manager)

  delegate :name, :to => :user, :prefix => true
end
