require 'rails_helper'

RSpec.describe NotificationWorker do
  let(:user) { create :user }

  let(:issue) { create :issue }

  describe '#perform' do
    before do
      user.user_to_project_connections.create :project => issue.project, :role => 'owner'
    end

    it { expect(NotificationWorker.new().perform(issue.id, user.id).size).to eq 1 }
  end
end
