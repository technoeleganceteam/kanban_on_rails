FactoryGirl.define do
  factory :test_girl do
  end
  factory :user do
    sequence(:email) { |n| "user_numero_#{ n }@mail.com" }

    password 'all_users_have_the_same_password'

    locale 'en'

    name 'Test user'

    trait :github_profile do
      after(:create) do |user|
        user.authentications << (create :authentication, :provider => 'github')
      end
    end

    trait :gitlab_profile do
      after(:create) do |user|
        user.authentications << (create :authentication, :provider => 'gitlab', :gitlab_private_token => 'token')
      end
    end

    trait :bitbucket_profile do
      after(:create) do |user|
        user.authentications << (create :authentication, :provider => 'bitbucket')
      end
    end

    factory :user_with_github_profile, :traits => [:github_profile]

    factory :user_with_gitlab_profile, :traits => [:gitlab_profile]

    factory :user_with_bitbucket_profile, :traits => [:bitbucket_profile]
  end

  factory :authentication do
    uid '1345'

    token 'sometoken'

    provider 'github'

    user
  end

  factory :issue do
    title 'Some title'

    project
  end

  factory :project do
    name 'Some project'

    github_full_name 'some/project'
  end

  factory :user_to_issue_connection do
    user

    issue
  end

  factory :user_to_project_connection do
    project

    user

    role 'member'
  end

  factory :section do
    name 'Some name'

    board
  end

  factory :column do
    name 'Some name'

    backlog false

    tags ['tag']

    board
  end

  factory :issue_to_section_connection do
    issue

    column

    section

    board
  end

  factory :board do
    name 'Some board'
  end

  factory :project_to_board_connection do
    project

    board
  end

  factory :user_to_board_connection do
    user

    board
  end

  factory :user_request do
    content 'Some content'

    user
  end

  factory :feedback do
    name 'Some name'

    content 'Some content'

    email 'some@mail.com'
  end

  factory :changelog do
    tag_name '1.0.0'

    last_commit_sha '123456'

    last_commit_date DateTime.now.utc

    project
  end

  factory :pull_request do
    merged_at DateTime.now.utc

    title 'Some title'

    changelog

    project
  end

  factory :pull_request_to_issue_connection do
    pull_request

    issue
  end

  factory :pull_request_subtask do
    pull_request
  end
end
