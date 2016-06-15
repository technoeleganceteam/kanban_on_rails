FactoryGirl.define do
  factory :test_girl do
  end
  factory :user do
    sequence(:email) { |n| "user_numero_#{ n }@mail.com" }

    password 'all_users_have_the_same_password'

    locale 'en'

    name 'Test user'
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
  end

  factory :column do
    name 'Some name'

    tags ['tag']
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
end
