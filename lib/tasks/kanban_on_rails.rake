namespace :kanban_on_rails do
  desc 'Run all specs and lints'
  task :run_all_specs_and_lints => :environment do
    sh('bundle exec rake spec')

    sh('bundle exec rubocop -c .rubocop.yml')

    sh('bundle exec rails_best_practices')

    sh('bundle exec brakeman')

    sh('bundle exec fasterer')

    sh('bundle exec slim-lint app/views')

    sh('bundle exec mdl -s config/markdown_ruleset.rb *.md')

    sh('npm run coffeelint')

    sh('npm run sass-lint')
  end
end
