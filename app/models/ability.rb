class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new

    cannot :read, :all

    can :payload_from_github, Project

    can :payload_from_bitbucket, Project

    if user.persisted?
      can :manage, User, :id => user.id

      can :settings, User, :id => user.id

      can :dashboard, User, :id => user.id

      can :read, User, :id => user.id

      can :manage, Authentication, :user_id => user.id

      can :read, Project do |project|
        project.user_ids.include?(user.id)
      end

      can :create, Project

      can :sync_with_github, Project

      can :sync_with_bitbucket, Project

      can :stop_sync_with_github, Project

      can :stop_sync_with_bitbucket, Project

      can :manage, Project do |project|
        project.user_to_project_connections.where(:user_id => user.id, :role => 'owner').first.present?
      end

      can :manage, Issue do |issue|
        issue.project.user_ids.include?(user.id)
      end
    end
  end
end
