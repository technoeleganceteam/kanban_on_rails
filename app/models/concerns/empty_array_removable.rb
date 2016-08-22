module EmptyArrayRemovable
  extend ActiveSupport::Concern

  included do
    before_validation :remove_empty_arrays
  end

  private

  def remove_empty_arrays
    attributes.each_key do |attribute|
      if self[attribute].is_a?(Array) && self[attribute].present?
        self[attribute] = self[attribute].reject(&:blank?)
      end
    end
  end
end
