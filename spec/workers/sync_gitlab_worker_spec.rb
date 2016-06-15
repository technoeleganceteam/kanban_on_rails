require 'rails_helper'

RSpec.describe SyncGitlabWorker do
  let(:user) { create :user }

  describe '#perform' do
    it { expect(SyncGitlabWorker.new.perform(user.id)).to eq nil }
  end
end
