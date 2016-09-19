require 'rails_helper'

RSpec.describe GenerateChangelogs do
  describe '#generate' do
    context 'when project is the github repository' do
      before do
        @user = create :user_with_github_profile

        project = create :project, :is_github_repository => true, :github_repository_id => 1,
          :close_issues => true

        create :issue, :github_issue_number => 1, :github_issue_id => 1, :project => project

        create :user_to_project_connection, :user => @user, :project => project, :role => 'owner'

        stub_request(:get, 'https://api.github.com/repos/some/project/tags?per_page=100').
          with(:headers => { 'Accept' => 'application/vnd.github.v3+json',
            'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'Authorization' => 'token sometoken', 'Content-Type' => 'application/json',
            'User-Agent' => 'Octokit Ruby Gem 4.3.0' }).
          to_return(:status => 200, :headers => {}, :body => [
            Hashie::Mash.new(
              :commit => { :sha => '123456', :author => { :date => DateTime.now.utc } },
              :name => '0.0.1'
            )
          ])

        stub_request(:get, 'https://api.github.com/repositories/1/commits/123456').
          with(:headers => { 'Accept' => 'application/vnd.github.v3+json',
            'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'Authorization' => 'token sometoken', 'Content-Type' => 'application/json',
            'User-Agent' => 'Octokit Ruby Gem 4.3.0' }).
          to_return(
            :status => 200, :headers => { 'Content-Type' => 'application/json' },
            :body => {
              :commit => { :sha => '123456', :author => { :date => DateTime.now.utc } },
              :name => '0.0.1'
            }.to_json
          )

        stub_request(:get, 'https://api.github.com/repos/some/project/pulls?per_page=100&state=closed').
          with(:headers => { 'Accept' => 'application/vnd.github.v3+json',
            'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'Authorization' => 'token sometoken', 'Content-Type' => 'application/json',
            'User-Agent' => 'Octokit Ruby Gem 4.3.0' }).
          to_return(:status => 200, :headers => {}, :body => [
            Hashie::Mash.new(
              :title => 'some title',
              :body => "1. [new][S] Some feature\nconnects to #1\nconnects to #2",
              :merged_at => DateTime.now.utc,
              :html_url => 'https://some.url',
              :id => 1,
              :user => { :login => 'login' }
            )
          ])

        stub_request(:get, 'https://api.github.com/repositories/1/issues/2').
          with(:headers => { 'Accept' => 'application/vnd.github.v3+json',
            'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'Authorization' => 'token sometoken', 'Content-Type' => 'application/json',
            'User-Agent' => 'Octokit Ruby Gem 4.3.0' }).
          to_return(
            :status => 200, :headers => { 'Content-Type' => 'application/json' },
            :body => {
              :title => 'Some title',
              :body => 'Some body',
              :labels => []
            }.to_json
          )
      end

      it { expect(GenerateChangelogs.new(:project => @user.projects.first).generate).to eq 1 }
    end

    context 'when project is the gitlab repository' do
      before do
        @user = create :user_with_gitlab_profile

        project = create :project, :is_gitlab_repository => true, :gitlab_repository_id => 1,
          :close_issues => true

        create :issue, :gitlab_issue_number => 1, :gitlab_issue_id => 1, :project => project

        create :user_to_project_connection, :user => @user, :project => project, :role => 'owner'

        stub_request(:get, 'https://gitlab.com/api/v3/projects/1/repository/tags').
          with(:headers => { 'Accept' => 'application/json', 'Private-Token' => 'token' }).
          to_return(:status => 200, :headers => {}, :body => [{
            :name => 'name',
            :commit => { 'id' => 1, :committed_date => DateTime.now.utc }
          }].to_json)

        stub_request(:get, 'https://gitlab.com/api/v3/projects/1/merge_requests?state=merged').
          with(:headers => { 'Accept' => 'application/json', 'Private-Token' => 'token' }).
          to_return(:status => 200, :headers => {}, :body => [{
            :id => 1,
            :iid => 1,
            :updated_at => DateTime.now.utc,
            :title => 'Some feature',
            :description => "1. [new][S] Some feature\nconnects to #1",
            :author => { :username => 'username', :weburl => 'https://some.url' }
          }].to_json)

        stub_request(:put, 'https://gitlab.com/api/v3/projects/1/issues/1').
          with(:body => 'title=Some%20title&description=&labels=&state_event=close',
            :headers => { 'Accept' => 'application/json', 'Private-Token' => 'token' }).
          to_return(:status => 200, :body => {}.to_json, :headers => {})
      end

      it { expect(GenerateChangelogs.new(:project => @user.projects.first).generate).to eq 1 }
    end

    context 'when project is the bitbucket repository' do
      before do
        @user = create :user_with_bitbucket_profile

        project = create :project, :is_bitbucket_repository => true, :bitbucket_slug => 'foo',
          :bitbucket_owner => 'bar', :close_issues => true

        create :issue, :bitbucket_issue_number => 1, :project => project

        create :user_to_project_connection, :user => @user, :project => project, :role => 'owner'

        stub_request(:get, 'https://api.bitbucket.org/1.0/repositories/bar/foo/tags/').
          with(:headers => { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'Authorization' => /.*/, 'Content-Type' => 'application/json',
            'User-Agent' => 'BitBucket Ruby Gem 0.1.7' }).
          to_return(:status => 200, :headers => {}, :body => [['0.0.1', {
            :utctimestamp => DateTime.now.utc,
            :raw_node => '123456'
          }]].to_json)

        stub_request(:get, 'https://api.bitbucket.org/2.0/repositories/bar/foo/pullrequests?state=merged').
          with(:headers => { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'Authorization' => /.*/, 'Content-Type' => 'application/json',
            'User-Agent' => 'BitBucket Ruby Gem 0.1.7' }).
          to_return(:status => 200, :headers => {}, :body => {
            :values => [
              :title => 'Some title',
              :id => 1,
              :description => "1. [new][S] Some feature\nconnects to #1",
              :merge_commit => { :hash => '123456' },
              :author => { :username => 'username', :links => { :html => { :href => 'https://some.url' } } },
              :links => { :html => { :href => 'https://some.url' } }
            ]
          }.to_json)

        stub_request(:get, 'https://api.bitbucket.org/2.0/repositories/bar/foo/commit/123456').
          with(:headers => { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'Authorization' => /.*/, 'Content-Type' => 'application/json',
            'User-Agent' => 'BitBucket Ruby Gem 0.1.7' }).
          to_return(:status => 200, :body => { :date => DateTime.now.utc }.to_json, :headers => {})
      end

      it { expect(GenerateChangelogs.new(:project => @user.projects.first).generate).to eq 1 }
    end
  end
end
