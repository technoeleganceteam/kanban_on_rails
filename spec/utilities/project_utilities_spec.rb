require 'rails_helper'

describe ProjectUtilities do
  describe '#check_gitlab_owner' do
    it { expect(ProjectUtilities.check_gitlab_owner(Hashie::Mash.new(:owner => nil), nil)).to eq 'member' }
  end
end
