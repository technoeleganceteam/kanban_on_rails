require 'rails_helper'

RSpec.describe SyncGithubIssueWorker do
  let(:issue) { create :issue }

  describe '#perform' do
    it { expect(SyncGithubIssueWorker.new().perform(issue.id, 1)).to eq nil }
  end
end
