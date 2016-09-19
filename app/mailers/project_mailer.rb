# Mailer for sending changelogs
class ProjectMailer < ApplicationMailer
  def changelogs_email(changelog_ids)
    @changelogs = Changelog.where(:id => changelog_ids).order('last_commit_date DESC')

    return unless @changelogs.any?

    @changelogs.first.project_emails_for_reports.each { |email| mail(:to => email, :subject => subject) }
  end

  private

  def subject
    first_changelog, last_changelog, first_tag_name = first_last_changelogs_and_first_tag_name

    versions = if first_changelog.id == last_changelog.id
      "#{ t 'release' } #{ first_tag_name }"
    else
      "#{ t 'releases' } #{ last_changelog.tag_name } - #{ first_tag_name }"
    end

    "#{ first_changelog.project.name } #{ versions }"
  end

  def first_last_changelogs_and_first_tag_name
    @changelogs.reload

    first_changelog = @changelogs.first

    [first_changelog, @changelogs.last, first_changelog.tag_name]
  end
end
