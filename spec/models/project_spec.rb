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

    context 'when project is github repository and raise Octokit::NotFound' do
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

        allow_any_instance_of(Octokit::Client).to receive(:update_contents).
          and_raise(Octokit::NotFound.new({}))
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

    context 'when project is gitlab repository and raise Gitlab::Error::NotFound' do
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

        stub_request(:post, 'https://gitlab.com/api/v3/projects/1/repository/files').
          with(:body => /.*/, :headers => { 'Accept' => 'application/json', 'Private-Token' => 'token' }).
          to_return(:status => 200, :body => '', :headers => {})

        allow_any_instance_of(Gitlab::Client).to receive(:edit_file).
          and_raise(Gitlab::Error::NotFound.new(GitlabResponseHelpers))
      end

      it { expect(@project.write_changelog).to eq false }
    end
  end

  describe '#fetch_and_create_github_issue' do
    before do
      user = create :user_with_github_profile

      @project = create :project, :is_github_repository => true, :github_repository_id => 1,
        :close_issues => true

      create :user_to_project_connection, :user => user, :project => @project, :role => 'owner'

      create :issue, :project => @project, :github_issue_id => 1, :github_issue_number => 1

      stub_request(:get, 'https://api.github.com/repositories/1/issues/1').
        with(:headers => { 'Accept' => 'application/vnd.github.v3+json',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Authorization' => 'token sometoken', 'Content-Type' => 'application/json',
          'User-Agent' => 'Octokit Ruby Gem 4.3.0' }).
        to_return(
          :status => 200, :headers => { 'Content-Type' => 'application/json' },
          :body => {
            :id => '1',
            :title => 'Some title',
            :labels => []
          }.to_json
        )
    end

    it { expect(@project.fetch_and_create_github_issue(1)).to eq true }
  end

  describe '#fetch_and_create_gitlab_issue' do
    before do
      user = create :user_with_gitlab_profile

      @project = create :project, :is_gitlab_repository => true, :gitlab_repository_id => 1

      create :issue, :project => @project, :gitlab_issue_id => 1, :gitlab_issue_number => 1

      create :user_to_project_connection, :user => user, :project => @project, :role => 'owner'

      stub_request(:get, 'https://gitlab.com/api/v3/projects/1/issues/1').
        with(:headers => { 'Accept' => 'application/json', 'Private-Token' => 'token' }).
        to_return(:status => 200, :body => { :id => 1, :title => 'test' }.to_json, :headers => {})
    end

    it { expect(@project.fetch_and_create_gitlab_issue(1)).to eq true }
  end

  describe '#fetch_and_create_bitbucket_issue' do
    before do
      user = create :user_with_bitbucket_profile

      @project = create :project, :is_bitbucket_repository => true, :bitbucket_owner => 'username',
        :bitbucket_slug => 'test'

      create :issue, :project => @project, :bitbucket_issue_id => 1, :bitbucket_issue_number => 1

      create :user_to_project_connection, :user => user, :project => @project, :role => 'owner'

      stub_request(:get, 'https://api.bitbucket.org/1.0/repositories/test/test/issues/1').
        with(:headers => { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Authorization' => /.*/, 'Content-Type' => 'application/json',
          'User-Agent' => 'BitBucket Ruby Gem 0.1.7' }).
        to_return(:status => 200, :body => { :id => 1, :title => 'test' }.to_json, :headers => {})

      stub_request(:get, 'https://api.bitbucket.org/1.0/repositories/username/test/issues/1').
        with(:headers => { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Authorization' => /.*/, 'Content-Type' => 'application/json',
          'User-Agent' => 'BitBucket Ruby Gem 0.1.7' }).
        to_return(:status => 200, :body => { :owner => {}, :title => 'test' }.to_json, :headers => {})
    end

    it { expect(@project.fetch_and_create_bitbucket_issue(1)).to eq true }
  end

  describe '#remove_hook_from_gitlab' do
    before do
      user = create :user_with_gitlab_profile

      @project = create :project, :is_gitlab_repository => true, :gitlab_repository_id => 1,
        :close_issues => true

      create :user_to_project_connection, :user => user, :project => @project, :role => 'owner'

      stub_request(:delete, 'https://gitlab.com/api/v3/projects/1/hooks/1').
        with(:headers => { 'Accept' => 'application/json', 'Private-Token' => 'token' }).
        to_return(:status => 200, :body => '', :headers => {})
    end

    it do
      expect(@project.remove_hook_from_gitlab(@project.gitlab_client_for_changelogs, Hashie::Mash.new(:id => 1))).
        to eq false
    end
  end

  describe '#remove_hook_from_github' do
    before do
      user = create :user_with_github_profile

      @project = create :project, :is_github_repository => true, :github_repository_id => 1,
        :close_issues => true

      create :user_to_project_connection, :user => user, :project => @project, :role => 'owner'

      stub_request(:delete, 'https://api.github.com/repos/some/project/hooks/1').
        with(:body => '{}', :headers => { 'Accept' => 'application/vnd.github.v3+json',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Authorization' => 'token sometoken', 'Content-Type' => 'application/json',
          'User-Agent' => 'Octokit Ruby Gem 4.3.0' }).
        to_return(:status => 200, :body => '', :headers => {})
    end

    it do
      expect(@project.remove_hook_from_github(@project.github_client_for_changelogs, Hashie::Mash.new(:id => 1))).
        to eq false
    end
  end

  describe '#check_gitlab_owner' do
    it { expect(project.check_gitlab_owner(Hashie::Mash.new(:owner => nil), nil)).to eq 'member' }
  end
end
