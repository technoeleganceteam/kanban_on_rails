# Module for assign content path for HighVoltage pages
module ContentPathable
  extend ActiveSupport::Concern

  included do
    before_action :assign_content_path
  end

  private

  def assign_content_path
    HighVoltage.content_path = "#{ self.class.name.sub('Controller', '').downcase }/"
  end
end
