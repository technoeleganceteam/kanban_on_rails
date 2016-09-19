# Class for issue to section connections business logic
class IssueToSectionConnection < ActiveRecord::Base
  belongs_to :issue

  belongs_to :project

  belongs_to :board

  belongs_to :section

  belongs_to :column
end
