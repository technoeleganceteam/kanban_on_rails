# Provide methods for working with Github stuff
module GithubUtilities
  class << self
    def pull_request_id_from_provider(pull_request)
      pull_request['id']
    end

    def last_commit_sha(tag)
      tag[:commit][:sha]
    end

    def pull_request_author_url(pull_request)
      pull_request['user']['html_url']
    end

    def pull_request_body(pull_request)
      pull_request['body']
    end

    def pull_request_created_by(pull_request)
      pull_request['user']['login']
    end

    def pull_request_merged_at(pull_request, _client, _project)
      pull_request['merged_at']
    end

    def pull_request_number_from_provider(pull_request)
      pull_request['number']
    end

    def pull_request_url(pull_request, _project)
      pull_request['html_url']
    end

    def pull_request_title(pull_request)
      pull_request['title']
    end

    def tag_name(tag)
      tag[:name]
    end

    def tag_name_and_last_commit_sha(tag)
      {
        :tag_name => tag_name(tag),
        :last_commit_sha => last_commit_sha(tag)
      }
    end

    def parse_params_from_update_issue(params)
      {
        :github_issue_id => params.try(:id),
        :github_issue_number => params.try(:number),
        :github_issue_comments_count => params.try(:comments),
        :github_issue_html_url => params.try(:html_url),
        :github_labels => params.try(:labels)
      }
    end
  end
end
