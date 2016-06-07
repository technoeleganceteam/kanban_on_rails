require 'rails_helper'

RSpec.describe Issue, :type => :model do
  let(:user) { create :user }
  
  let(:issue) { create :issue }

  let(:user_to_issue_connection) { create :user_to_issue_connection, :user => user, :issue => issue }
  
  describe '#sync_with_github' do
    before do 
      stub_request(:patch, 'https://api.github.com/repos/some/project/issues/').
        with(:body => '{"labels":[]}', :headers => {'Accept' => 'application/vnd.github.v3+json',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Authorization' => 'token token',
          'Content-Type' => 'application/json', 'User-Agent' => 'Octokit Ruby Gem 4.3.0'}).
        to_return(:status => 200, :body => '', :headers => {}) 
      
      user.authentications.create! :uid => 123, :provider => 'github', :token => 'token'
    end

    it { expect(user_to_issue_connection.issue.sync_with_github(user.id)).to eq '' }
  end
end
