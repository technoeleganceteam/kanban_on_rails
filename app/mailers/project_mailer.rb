class ProjectMailer < ApplicationMailer
  def changelogs_email(changelog_ids)
    @changelogs = Changelog.where(:id => changelog_ids).order('last_commit_date DESC')

    return unless @changelogs.any?

    generate_subject

    @changelogs.first.project.emails_for_reports.each do |email|
      mail(:to => email, :subject => @subject)
    end
  end

  private

  def generate_subject
    @changelogs.reload

    first_changelog = @changelogs.first

    last_changelog = @changelogs.last

    versions = if first_changelog.id == last_changelog.id
      "#{ t 'release' } #{ first_changelog.tag_name }"
    else
      "#{ t 'releases' } #{ last_changelog.tag_name } - #{ first_changelog.tag_name }"
    end

    @subject = "#{ first_changelog.project.name } #{ versions }"
  end
end
