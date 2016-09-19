require 'rails_helper'

describe GitlabUtilities do
  describe '.issue_link' do
    it { expect(GitlabUtilities.issue_link('test', '1')).to eq 'https://gitlab.com/test/issues/1' }
  end
end
