require 'rails_helper'

RSpec.describe SyncBitbucketIssueWorker do
  let(:issue) { create :issue }

  describe '#perform' do
    it { expect(SyncBitbucketIssueWorker.new().perform(issue.id, 1)).to eq nil }
  end
end
