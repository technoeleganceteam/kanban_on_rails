require 'rails_helper'

RSpec.describe GenerateChangelogWorker do
  let(:project) { create :project, :is_github_repository => true }

  describe '#perform' do
    it { expect(GenerateChangelogWorker.new.perform(project.id)).to eq nil }
  end
end
