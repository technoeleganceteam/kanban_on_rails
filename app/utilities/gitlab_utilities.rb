# Provide methods for working with Gitlab stuff
module GitlabUtilities
  class << self
    def pull_request_title(pull_request)
      pull_request.title
    end

    def pull_request_id_from_provider(pull_request)
      pull_request.id
    end

    def pull_request_body(pull_request)
      pull_request.description
    end

    def pull_request_created_by(pull_request)
      pull_request.author.username
    end

    def pull_request_author_url(pull_request)
      pull_request.author.web_url
    end

    def pull_request_number_from_provider(pull_request)
      pull_request.iid
    end

    def pull_request_merged_at(pull_request, _client, _project)
      # We don't know about when merge request was merged from gitlab,
      # we can only get merge request updated at(https://github.com/gitlabhq/gitlabhq/blob/dad406da23f7a4d94f9f8df1a4b8743dc0e9dc96/lib/gitlab/github_import/pull_request_formatter.rb#L95)
      # and consider it as merged at date.
      # But often it is about 5 seconds later than it was realy merged.
      # If you know how to improve that method, please contact me or send PR.
      DateTime.parse(pull_request.updated_at).utc - 5.seconds
    end

    def tag_name(tag)
      tag.name
    end

    def last_commit_sha(tag)
      tag.commit.id
    end

    def pull_request_url(pull_request, project)
      "#{ Settings.gitlab_base_url }/#{ project.gitlab_full_name }/merge_requests/#{ pull_request.iid }"
    end

    def issue_status_to_sync(issue)
      issue.closed? ? { :state_event => 'close' } : {}
    end

    def issue_link(gitlab_full_name, gitlab_issue_id)
      "#{ Settings.gitlab_base_url }/#{ gitlab_full_name }/issues/#{ gitlab_issue_id }"
    end
  end
end
