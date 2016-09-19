# Module defining method to remove empty arrays for array fields
module EmptyArrayRemovable
  extend ActiveSupport::Concern

  included do
    before_validation :remove_empty_arrays
  end

  private

  def remove_empty_arrays
    attributes.each_key do |attribute|
      field = self[attribute]

      self[attribute] = field.reject(&:blank?) if field.is_a?(Array) && field.present?
    end
  end
end
