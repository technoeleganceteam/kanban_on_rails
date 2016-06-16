require 'rails_helper'

describe User, :type => :model do
  let(:user) { create :user, :email => 'test@mail.com' }

  let(:user2) { create :user }

  describe '#gravatar_url' do
    subject { user.gravatar_url }

    it { is_expected.to eq 'https://secure.gravatar.com/avatar/97dfebf4098c0f5c16bca61e2b76c373' }
  end

  describe '#avatar' do
    subject { user.avatar }

    it { is_expected.to eq 'https://secure.gravatar.com/avatar/97dfebf4098c0f5c16bca61e2b76c373' }
  end

  describe '#sync_github' do
    before do
      project = create :project, :github_repository_id => 123, :name => 'Some name'

      user.user_to_project_connections.create :project => project, :role => 'owner'

      stub_request(:get, 'https://api.github.com/user/repos?per_page=100').
        with(:headers => { 'Accept' => 'application/vnd.github.v3+json',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Authorization' => 'token token', 'Content-Type' => 'application/json',
          'User-Agent' => 'Octokit Ruby Gem 4.3.0' }).
        to_return(:status => 200, :headers => {}, :body => [
          Hashie::Mash.new(
            :id => 123,
            :name => 'Some name',
            :full_name => 'some/name',
            :permissions => { :admin => true }
          ),
          Hashie::Mash.new(
            :id => 1,
            :name => 'Some name',
            :full_name => 'some/name',
            :permissions => { :admin => true }
          )
        ])

      stub_request(:get, 'https://api.github.com/repos/some/name/issues?per_page=100').
        with(:headers => { 'Accept' => 'application/vnd.github.v3+json',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Authorization' => 'token token', 'Content-Type' => 'application/json',
          'User-Agent' => 'Octokit Ruby Gem 4.3.0' }).
        to_return(:status => 200, :headers => {}, :body => [Hashie::Mash.new(:id => 123,
          :title => 'Some name',
          :body => 'some/name',
          :number => 1,
          :labels => [{ :name => 'test' }])])

      stub_request(:get, 'https://api.github.com/repos/some/name/hooks?per_page=100').
        with(:headers => { 'Accept' => 'application/vnd.github.v3+json',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Authorization' => 'token token', 'Content-Type' => 'application/json',
          'User-Agent' => 'Octokit Ruby Gem 4.3.0' }).
        to_return(:status => 200, :headers => {}, :body => [Hashie::Mash.new(:config => { :url => 'foo' })])

      stub_request(:post, 'https://api.github.com/repos/some/name/hooks').
        with(:body => /.*/, :headers => { 'Accept' => 'application/vnd.github.v3+json',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Authorization' => 'token token',
          'Content-Type' => 'application/json', 'User-Agent' => 'Octokit Ruby Gem 4.3.0' }).
        to_return(:status => 200, :body => '', :headers => {})

      user.authentications.create! :uid => 123, :provider => 'github', :token => 'token'
    end

    it { expect(user.sync_github.size).to eq 8 }
  end

  describe '#sync_gitlab' do
    before do
      project = create :project, :gitlab_repository_id => 1, :name => 'Some name'

      user2.user_to_project_connections.create :project => project, :role => 'owner'

      stub_request(:get, 'https://gitlab.com/api/v3/projects').
        with(:headers => { 'Accept' => 'application/json', 'Private-Token' => 'token' }).
        to_return(:status => 200, :headers => {}, :body => [{
          :id => 1,
          :name => 'name',
          :owner => { 'name' => 'username' }
        }, {
          :id => 2,
          :name => 'name2',
          :owner => { 'name' => 'username2' }
        }].to_json)

      stub_request(:get, 'https://gitlab.com/api/v3/user').
        with(:headers => { 'Accept' => 'application/json', 'Private-Token' => 'token' }).
        to_return(:status => 200, :headers => {}, :body => {
          :name => 'name',
          :owner => { 'name' => 'username' }
        }.to_json)

      stub_request(:get, 'https://gitlab.com/api/v3/projects/1/issues').
        with(:headers => { 'Accept' => 'application/json', 'Private-Token' => 'token' }).
        to_return(:status => 200, :headers => {}, :body => [{
          :id => 1,
          :title => 'title'
        }].to_json)

      stub_request(:get, 'https://gitlab.com/api/v3/projects/2/issues').
        with(:headers => { 'Accept' => 'application/json', 'Private-Token' => 'token' }).
        to_return(:status => 200, :headers => {}, :body => [{
          :id => 1,
          :title => 'title'
        }].to_json)

      stub_request(:post, 'https://gitlab.com/api/v3/projects/1/hooks').
        with(:body => /.*/, :headers => { 'Accept' => 'application/json', 'Private-Token' => 'token' }).
        to_return(:status => 200, :headers => {}, :body => [{
          :url => 'http://example.com'
        }].to_json)

      stub_request(:get, 'https://gitlab.com/api/v3/projects/1/hooks').
        with(:headers => { 'Accept' => 'application/json', 'Private-Token' => 'token' }).
        to_return(:status => 200, :headers => {}, :body => [{
          :url => 'http://example.com'
        }].to_json)

      stub_request(:get, 'https://gitlab.com/api/v3/projects/2/hooks').
        with(:headers => { 'Accept' => 'application/json', 'Private-Token' => 'token' }).
        to_return(:status => 200, :headers => {}, :body => [{
          :url => 'http://example.com'
        }].to_json)

      stub_request(:post, 'https://gitlab.com/api/v3/projects/2/hooks').
        with(:body => /.*/,
        :headers => { 'Accept' => 'application/json', 'Private-Token' => 'token' }).
        to_return(:status => 200, :body => '', :headers => {})

      user.authentications.create! :uid => 123, :provider => 'gitlab', :token => 'token',
        :gitlab_private_token => 'token'
    end

    it { expect(user.sync_gitlab.size).to eq 8 }
  end

  describe '#sync_bitbucket' do
    before do
      project = create :project, :bitbucket_full_name => 'username/slug', :name => 'Some name'

      user.user_to_project_connections.create :project => project, :role => 'owner'

      stub_request(:get, 'https://api.bitbucket.org/1.0/user/repositories?user=username').
        with(:headers => { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Authorization' => /.*/, 'Content-Type' => 'application/json',
          'User-Agent' => 'BitBucket Ruby Gem 0.1.7' }).
        to_return(:status => 200, :headers => {}, :body => [{
          :slug => 'slug',
          :name => 'name',
          :owner => 'username'
        }, {
          :slug => 'slug2',
          :name => 'name2',
          :owner => 'username'
        }].to_json)

      stub_request(:get, 'https://api.bitbucket.org/1.0/user/repositories').
        with(:headers => { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Authorization' => /.*/, 'Content-Type' => 'application/json',
          'User-Agent' => 'BitBucket Ruby Gem 0.1.7' }).
        to_return(:status => 200, :headers => {}, :body => [{
          :slug => 'slug',
          :name => 'name',
          :owner => 'username'
        }, {
          :slug => 'slug2',
          :name => 'name2',
          :owner => 'username'
        }].to_json)

      stub_request(:get, 'https://api.bitbucket.org/1.0/user').
        with(:headers => { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Authorization' => /.*/, 'User-Agent' => 'BitBucket Ruby Gem 0.1.7' }).
        to_return(:status => 200, :headers => {}, :body => {
          :username => 'username'
        }.to_json.to_s)

      stub_request(:get, 'https://api.bitbucket.org/1.0/repositories/username/slug/issues').
        with(:headers => { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Authorization' => /.*/, 'User-Agent' => 'BitBucket Ruby Gem 0.1.7' }).
        to_return(:status => 200, :headers => {}, :body => { :issues => [{
          :local_id => 1,
          :title => 'Some title',
          :content => 'Some content'
        }] }.to_json.to_s)

      stub_request(:get, 'https://api.bitbucket.org/1.0/repositories/username/slug2/issues').
        with(:headers => { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Authorization' => /.*/, 'User-Agent' => 'BitBucket Ruby Gem 0.1.7' }).
        to_return(:status => 200, :headers => {}, :body => { :issues => [{
          :local_id => 1,
          :title => 'Some title',
          :content => 'Some content'
        }] }.to_json.to_s)

      stub_request(:get, 'https://api.bitbucket.org/2.0/repositories/username/slug/hooks').
        with(:headers => { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Authorization' => /.*/, 'User-Agent' => 'BitBucket Ruby Gem 0.1.7' }).
        to_return(:status => 200, :headers => {}, :body => { :values => {} }.to_json.to_s)

      stub_request(:post, 'https://api.bitbucket.org/2.0/repositories/username/slug/hooks').
        with(:body => /.*/, :headers => { 'Accept' => '*/*',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Authorization' => /.*/, 'Content-Type' => 'application/x-www-form-urlencoded',
          'User-Agent' => 'BitBucket Ruby Gem 0.1.7' }).
        to_return(:status => 200, :body => {}.to_json.to_s, :headers => {})

      stub_request(:get, 'https://api.bitbucket.org/2.0/repositories/username/slug2/hooks').
        with(:headers => { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Authorization' => /.*/, 'User-Agent' => 'BitBucket Ruby Gem 0.1.7' }).
        to_return(:status => 200, :headers => {}, :body => {
          :values => [{ :description => 'kanbanonrails' }]
        }.to_json.to_s)

      stub_request(:post, 'https://api.bitbucket.org/2.0/repositories/username/slug/hooks').
        with(:body => /.*/, :headers => { 'Accept' => '*/*',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Authorization' => /.*/, 'Content-Type' => 'application/json',
          'User-Agent' => 'BitBucket Ruby Gem 0.1.7' }).
        to_return(:status => 200, :headers => {}, :body => {}.to_json.to_s)

      project_2 = create :project, :github_repository_id => 123, :name => 'Some name'

      user.user_to_project_connections.create :project => project_2, :role => 'owner'

      user.authentications.create! :uid => 123, :provider => 'bitbucket', :token => 'token', :secret => 'secret'
    end

    it { expect(user.sync_bitbucket.size).to eq 8 }
  end

  describe '#remove_hooks_from_bitbucket' do
    before do
      project = create :project, :is_bitbucket_repository => true, :name => 'Some name',
        :bitbucket_owner => 'owner', :bitbucket_slug => 'slug'

      user.authentications.create :provider => 'bitbucket', :token => 'token', :secret => 'secret', :uid => 12

      user.user_to_project_connections.create :project => project, :role => 'owner'

      stub_request(:get, 'https://api.bitbucket.org/2.0/repositories/owner/slug/hooks').
        with(:headers => { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Authorization' => /.*/, 'Content-Type' => 'application/json',
          'User-Agent' => 'BitBucket Ruby Gem 0.1.7' }).
        to_return(:status => 200, :headers => {},
          :body => { :values => [{ :description => 'kanbanonrails', :uuid => '{12}' }] }.to_json.to_s)

      stub_request(:delete, 'https://api.bitbucket.org/2.0/repositories/owner/slug/hooks/12').
        with(:headers => { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Authorization' => /.*/, 'Content-Type' => 'application/json',
          'User-Agent' => 'BitBucket Ruby Gem 0.1.7' }).
        to_return(:status => 200, :body => {}.to_json.to_s, :headers => {})
    end

    it { expect(user.remove_hooks_from_bitbucket).to eq nil }
  end

  describe '#remove_hooks_from_github' do
    before do
      project = create :project, :is_github_repository => true, :name => 'Some name',
        :github_repository_id => 1

      user.authentications.create :provider => 'github', :token => 'token', :secret => 'secret', :uid => 12

      user.user_to_project_connections.create :project => project, :role => 'owner'

      stub_request(:get, 'https://api.github.com/repos/some/project/hooks?per_page=100').
        with(:headers => { 'Accept' => 'application/vnd.github.v3+json',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Authorization' => 'token token', 'Content-Type' => 'application/json',
          'User-Agent' => 'Octokit Ruby Gem 4.3.0' }).
        to_return(:status => 200, :headers => {},
          :body => [Hashie::Mash.new(:config => { :url => Settings.webhook_host })])
    end

    it { expect(user.remove_hooks_from_github).to eq nil }
  end

  describe '#remove_hooks_from_gitlab' do
    before do
      project = create :project, :is_gitlab_repository => true, :name => 'Some name',
        :gitlab_repository_id => 1

      user.authentications.create :provider => 'gitlab', :token => 'token', :secret => 'secret', :uid => 12,
        :gitlab_private_token => 'token'

      user.user_to_project_connections.create :project => project, :role => 'owner'

      stub_request(:get, 'https://gitlab.com/api/v3/projects/1/hooks').
        with(:headers => { 'Accept' => 'application/json', 'Private-Token' => 'token' }).
        to_return(:status => 200, :headers => {}, :body => [{
          :url => Settings.webhook_host
        }].to_json)
    end

    it { expect(user.remove_hooks_from_gitlab).to eq nil }
  end
end
