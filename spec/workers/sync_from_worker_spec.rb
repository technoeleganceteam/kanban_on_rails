require 'rails_helper'

describe SyncFromWorker do
  let(:user) { create :user }

  describe '#perform' do
    context 'when sync users projects, issues and hooks from github' do
      it { expect(SyncFromWorker.new.perform(user.id, 'github')).to eq nil }
    end

    context 'when sync users projects, issues and hooks from gitlab' do
      it { expect(SyncFromWorker.new.perform(user.id, 'gitlab')).to eq nil }
    end

    context 'when sync users projects, issues and hooks from bitbucket' do
      it { expect(SyncFromWorker.new.perform(user.id, 'bitbucket')).to eq nil }
    end
  end
end
