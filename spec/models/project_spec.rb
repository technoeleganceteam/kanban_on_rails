require 'rails_helper'

RSpec.describe Project, :type => :model do
  let(:project) { create :project }

  describe '#parse_issue_params_from_github_webhook' do
    it do
      expect(project.parse_issue_params_from_github_webhook(:id => 1, :number => 1,
      :title => 'Some totle', :labels => [{ :some => 'label' }])).to eq true
    end
  end

  describe '#parse_issue_params_from_bitbucket_webhook' do
    it do
      expect(project.parse_issue_params_from_bitbucket_webhook(:id => 1, :title => 'Some title',
      :content => { :raw => 'content' })).to eq true
    end
  end

  describe '#parse_issue_params_from_gitlab_webhook' do
    it { expect(project.parse_issue_params_from_gitlab_webhook(:id => 1, :title => 'Some title')).to eq true }
  end

  describe '#open_issues' do
    it { expect(project.open_issues).to eq 0 }
  end

  describe '#write_changelog' do
    context 'when project is github repository' do
      before do
        user = create :user_with_github_profile

        @project = create :project, :is_github_repository => true, :github_repository_id => 1,
          :close_issues => true

        create :user_to_project_connection, :user => user, :project => @project, :role => 'owner'

        create :changelog, :project => @project

        stub_request(:get, 'https://api.github.com/repositories/1/contents/CHANGELOG.md').
          with(:headers => { 'Accept' => 'application/vnd.github.v3+json',
            'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'Authorization' => 'token sometoken', 'Content-Type' => 'application/json',
            'User-Agent' => 'Octokit Ruby Gem 4.3.0' }).
          to_return(
            :status => 200, :headers => { 'Content-Type' => 'application/json' },
            :body => {
              :sha => '123456'
            }.to_json
          )

        stub_request(:put, 'https://api.github.com/repositories/1/contents/CHANGELOG.md').
          with(:body => /.*/, :headers => { 'Accept' => 'application/vnd.github.v3+json',
            'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'Authorization' => 'token sometoken', 'Content-Type' => 'application/json',
            'User-Agent' => 'Octokit Ruby Gem 4.3.0' }).
          to_return(:status => 200, :body => '', :headers => {})
      end

      it { expect(@project.write_changelog).to eq '' }
    end

    context 'when project is gitlab repository' do
      before do
        user = create :user_with_gitlab_profile

        @project = create :project, :is_gitlab_repository => true, :gitlab_repository_id => 1,
          :close_issues => true

        create :user_to_project_connection, :user => user, :project => @project, :role => 'owner'

        create :changelog, :project => @project

        stub_request(:get,
          'https://gitlab.com/api/v3/projects/1/repository/files?file_path=CHANGELOG.md&ref=master').
          with(:headers => { 'Accept' => 'application/json', 'Private-Token' => 'token' }).
          to_return(:status => 200, :body => '', :headers => {})

        stub_request(:put, 'https://gitlab.com/api/v3/projects/1/repository/files').
          with(:body => /.*/, :headers => { 'Accept' => 'application/json', 'Private-Token' => 'token' }).
          to_return(:status => 200, :body => '', :headers => {})
      end

      it { expect(@project.write_changelog).to eq false }
    end
  end
end
