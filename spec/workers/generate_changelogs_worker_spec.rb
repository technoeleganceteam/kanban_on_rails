require 'rails_helper'

describe GenerateChangelogsWorker do
  let(:project) { create :project, :is_github_repository => true }

  describe '#perform' do
    it { expect(GenerateChangelogsWorker.new.perform(project.id)).to eq nil }
  end
end
