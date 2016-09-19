require 'rails_helper'

describe SyncToWorker do
  let(:issue) { create :issue }

  describe '#perform' do
    context 'when sync users issue to github' do
      it { expect(SyncToWorker.new.perform(issue.id, 1, 'github')).to eq nil }
    end

    context 'when sync users issue to gitlab' do
      it { expect(SyncToWorker.new.perform(issue.id, 1, 'gitlab')).to eq nil }
    end

    context 'when sync users issue to bitbucket' do
      it { expect(SyncToWorker.new.perform(issue.id, 1, 'bitbucket')).to eq nil }
    end
  end
end
