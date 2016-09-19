# Provide methods for working with Bitbucket stuff
module BitbucketUtilities
  class << self
    def pull_request_id_from_provider(pull_request)
      pull_request.id
    end

    def last_commit_sha(tag)
      tag.last['raw_node']
    end

    def pull_request_author_url(pull_request)
      pull_request.author['links']['html']['href']
    end

    def pull_request_body(pull_request)
      pull_request.description
    end

    def pull_request_created_by(pull_request)
      pull_request.author.username
    end

    def pull_request_number_from_provider(pull_request)
      pull_request.id
    end

    def pull_request_title(pull_request)
      pull_request.title
    end

    def pull_request_url(pull_request, _project)
      pull_request['links']['html']['href']
    end

    def tag_name(tag)
      tag.first
    end

    def pull_request_merged_at(pull_request, client, project)
      DateTime.parse(client.repos.commit.list(project.bitbucket_owner,
        project.bitbucket_slug, pull_request['merge_commit']['hash'])['date']).utc
    end

    def issue_status_to_sync(issue)
      issue.closed? ? { :status => 'resolved' } : {}
    end

    def issue_link(bitbucket_full_name, bitbucket_issue_id)
      "#{ Settings.bitbucket_base_url }/#{ bitbucket_full_name }/issues/#{ bitbucket_issue_id }"
    end
  end
end
