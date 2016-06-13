class ProjectToBoardConnection < ActiveRecord::Base
  belongs_to :project

  belongs_to :board
end
