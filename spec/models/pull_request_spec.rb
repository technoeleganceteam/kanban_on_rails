require 'rails_helper'

RSpec.describe PullRequest, :type => :model do
  describe '#pull_request_info_for_report' do
    before { @pull_request = create :pull_request, :gitlab_url => 'https://gitlab.com/test' }

    it do
      expect(@pull_request.pull_request_info_for_report).
        to eq "Some title ([#](https://gitlab.com/test) by [@]())\n"
    end
  end
end
