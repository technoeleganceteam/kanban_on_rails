class Ability
  include CanCan::Ability

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable MethodLength
  def initialize(user)
    user ||= User.new

    cannot :read, :all

    can :payload_from_github, Project

    can :payload_from_bitbucket, Project

    can :read, UserRequest

    if user.persisted?
      can :manage, User, :id => user.id

      can :settings, User, :id => user.id

      can :dashboard, User, :id => user.id

      can :read, User, :id => user.id

      can :manage, Authentication, :user_id => user.id

      can :read, Project do |project|
        project.user_ids.include?(user.id)
      end

      can :read, Board do |board|
        board.user_ids.include?(user.id)
      end

      can :create, Project

      can :create, Board

      can :sync_with_github, Project

      can :sync_with_gitlab, Project

      can :sync_with_bitbucket, Project

      can :stop_sync_with_github, Project

      can :stop_sync_with_bitbucket, Project

      can :stop_sync_with_gitlab, Project

      can :manage, UserRequest, :user_id => user.id

      can :manage, Board do |board|
        board.user_to_board_connections.find_by(:user_id => user.id, :role => 'owner').present?
      end

      can :manage, Project do |project|
        project.user_to_project_connections.find_by(:user_id => user.id, :role => 'owner').present?
      end

      can :manage, Changelog do |changelog|
        changelog.project.user_ids.include?(user.id)
      end

      can :create, Issue

      can :manage, Issue do |issue|
        issue.project.user_ids.include?(user.id) if issue.project.present?
      end
    end
  end
end
