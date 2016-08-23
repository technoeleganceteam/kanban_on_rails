class ChangelogsController < ApplicationController
  load_and_authorize_resource :project

  load_and_authorize_resource :changelog, :through => :project

  def index
    @changelogs = @project.changelogs.order('last_commit_date DESC').page(params[:page])
  end

  def show
    respond_to do |format|
      format.text { render :layout => false, :formats => [:html] }

      format.html { render }
    end
  end

  def resend
    ProjectMailer.changelogs_email([@changelog.id]).deliver_later if @project.emails_for_reports.any?

    redirect_to project_changelogs_url, :flash => { :notice => I18n.t('changelog_has_been_resent') }
  end

  def sync
    GenerateChangelogWorker.perform_async(@project.id)

    redirect_to project_changelogs_url, :flash => { :notice => I18n.t('changelogs_has_been_synced') }
  end
end
