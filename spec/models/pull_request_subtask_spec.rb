require 'rails_helper'

RSpec.describe PullRequestSubtask, :type => :model do
  describe '#subtask_info_for_report' do
    before { @subtask = create :pull_request_subtask }

    it { expect(@subtask.info_for_report).to eq "Subtask description\n" }
  end
end
