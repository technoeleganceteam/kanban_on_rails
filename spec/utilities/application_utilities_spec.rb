require 'rails_helper'

describe ApplicationUtilities do
  describe '.language_options_for_settings_select' do
    it { expect(ApplicationUtilities.language_options_for_settings_select.size).to eq 71 }
  end
end
