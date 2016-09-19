require 'rails_helper'

describe BitbucketUtilities do
  describe '.issue_link' do
    it { expect(BitbucketUtilities.issue_link('test', '1')).to eq 'https://bitbucket.com/test/issues/1' }
  end
end
