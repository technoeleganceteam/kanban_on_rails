require 'rails_helper'

RSpec.describe SyncGithubWorker do
  let(:user) { create :user }

  describe '#perform' do
    it { expect(SyncGithubWorker.new().perform(user.id)).to eq nil }
  end
end
