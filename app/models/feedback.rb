# Class for feedbacks business logic
class Feedback < ActiveRecord::Base
  validates :name, :length => { :maximum => Settings.max_string_field_size }, :presence => true

  validates :content, :length => { :maximum => Settings.max_text_field_size }, :presence => true

  validates :email, :presence => true, :length => { :maximum => Settings.max_string_field_size },
    :format => { :with => /\A[^@]+@[^@]+\z/ }
end
