# Project utilities
module ProjectUtilities
  class << self
    def bitbucket_special_attributes(repo)
      {
        :bitbucket_slug => repo.slug,
        :bitbucket_owner => repo.owner
      }
    end

    def github_special_attributes(repo)
      {
        :github_url => repo.html_url,
        :github_full_name => repo.full_name
      }
    end

    def gitlab_special_attributes(repo)
      {
        :gitlab_url => repo.web_url,
        :gitlab_full_name => repo.path_with_namespace
      }
    end

    def check_bitbucket_owner(repo, client)
      repo.owner == client.user_api.profile.dig(:user, :username) ? 'owner' : 'member'
    end

    def check_gitlab_owner(repo, client)
      owner = repo.owner

      if owner.present?
        owner.name == client.user.name ? 'owner' : 'member'
      else
        'member'
      end
    end

    def check_github_owner(repo, _client)
      repo.permissions[:admin] == true ? 'owner' : 'member'
    end
  end
end
