require 'rails_helper'

RSpec.describe SyncGitlabIssueWorker do
  let(:issue) { create :issue }

  describe '#perform' do
    it { expect(SyncGitlabIssueWorker.new.perform(issue.id, 1)).to eq nil }
  end
end
