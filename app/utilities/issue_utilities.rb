# Issue utilities
module IssueUtilities
  class << self
    def github_state_to_sync(github_issue)
      state = github_issue.state

      state.present? ? state : 'open'
    end

    def github_state_to_hook(params)
      state = params[:state]

      state.present? ? state : 'open'
    end

    def parse_attributes_for_update(params, issue)
      {
        :id => params[:id],
        :tags => issue.parse_tags(params[:source_column_id], params[:target_column_id])
      }
    end

    def params_from_bitbucket_api(bitbucket_params)
      {
        :title => bitbucket_params.title,
        :body => bitbucket_params.content,
        :state => bitbucket_params[:status] == 'resolved' ? 'closed' : 'open',
        :bitbucket_issue_number => bitbucket_params.local_id,
        :bitbucket_issue_comment_count => bitbucket_params.comment_count
      }
    end

    def params_from_gitlab_api(gitlab_params)
      {
        :title => gitlab_params.title,
        :body => gitlab_params.description,
        :gitlab_issue_number => gitlab_params.id,
        :state => gitlab_params.state == 'closed' ? 'closed' : 'open',
        :tags => gitlab_params.labels
      }
    end

    def params_from_gitlab_hook(gitlab_hook_params)
      {
        :title => gitlab_hook_params[:title],
        :body => gitlab_hook_params[:description],
        :gitlab_issue_number => gitlab_hook_params[:iid],
        :state => gitlab_hook_params[:state] == 'closed' ? 'closed' : 'open'
      }
    end

    def params_from_bitbucket_hook(bitbucket_hook_params)
      {
        :title => bitbucket_hook_params[:title],
        :body => bitbucket_hook_params[:content][:raw],
        :bitbucket_issue_number => bitbucket_hook_params[:id],
        :state => bitbucket_hook_params[:state] == 'resolved' ? 'closed' : 'open'
      }
    end

    def tags_from_github(params)
      params.labels.map(&:name)
    end

    def github_labels(label_params)
      label_params.to_a.map(&:to_a)
    end

    def github_tags(params_for_tags)
      params_for_tags[:labels].to_a.map { |label| label[:name] }
    end
  end

  def self.params_from_github_api(github_params)
    {
      :title => github_params.title[0..(Settings.max_string_field_size - 1)],
      :body => github_params.body,
      :state => github_state_to_sync(github_params),
      :github_issue_comments_count => github_params.comments,
      :github_issue_html_url => github_params.html_url,
      :tags => tags_from_github(github_params),
      :github_labels => github_labels(github_params.labels),
      :github_issue_number => github_params.number
    }
  end

  def self.params_from_github_hook(github_hook_params)
    {
      :title => github_hook_params[:title],
      :body => github_hook_params[:body],
      :github_issue_comments_count => github_hook_params[:comments],
      :github_issue_html_url => github_hook_params[:html_url],
      :tags => github_tags(github_hook_params),
      :github_labels => github_labels(github_hook_params[:labels]),
      :state => IssueUtilities.github_state_to_hook(github_hook_params),
      :github_issue_number => github_hook_params[:number].to_i
    }
  end
end
