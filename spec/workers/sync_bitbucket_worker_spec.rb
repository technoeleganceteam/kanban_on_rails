require 'rails_helper'

RSpec.describe SyncBitbucketWorker do
  let(:user) { create :user }

  describe '#perform' do
    it { expect(SyncBitbucketWorker.new().perform(user.id)).to eq nil }
  end
end
