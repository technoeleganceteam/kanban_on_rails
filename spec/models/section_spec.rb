require 'rails_helper'

RSpec.describe Section, :type => :model do
  let(:section) { create :section }

  describe '#before_destroy' do
    it { expect(section.update_attribute(:tags, section.tags + ['bar'])).to eq true }
  end
end
