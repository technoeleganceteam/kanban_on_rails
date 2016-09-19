# Module for provide method to define a provider of issues or pull requests
module Providerable
  extend ActiveSupport::Concern

  def provider
    Settings.issues_providers.map do |provider|
      provider if send("#{ provider }_#{ self.class == Issue ? 'issue_id' : 'url' }").present?
    end.compact.first
  end
end
