# Class for user requests business logic
class UserRequest < ActiveRecord::Base
  belongs_to :user

  validates :content, :presence => true, :length => { :maximum => Settings.max_text_field_size }

  delegate :name, :to => :user, :prefix => true
end
