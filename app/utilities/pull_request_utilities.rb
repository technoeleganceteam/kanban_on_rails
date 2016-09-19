# Pull requests utilities
module PullRequestUtilities
  class << self
    def description_from_fetched_data(subtask_content)
      /[0-9]*\.*\s*(\[\w*\])*(.*)/m.match(subtask_content).try(:[], -1).try(:strip).to_s
    end

    def story_points_from_fetched_data(subtask_content)
      subtask_content.scan(/^[0-9]*\.*\s*\[.*\]/m).first.to_s.
        scan(/\[\w*?\]/).try(:[], 1).to_s.sub(']', '').sub('[', '')
    end

    def task_type_from_fetched_data(subtask_content)
      subtask_content.scan(/^[0-9]*\.*\s*\[.*\]/m).first.to_s.
        scan(/\[\w*?\]/).first.to_s.sub(']', '').sub('[', '')
    end
  end
end
