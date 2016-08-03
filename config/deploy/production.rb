set :rvm_type, :system

set :rvm_ruby_version, 'ruby-2.3.1@kanban_on_rails'

set :rails_env, 'production'

set :stage, 'production'

server Settings.production_server_deploy_host,
  :user => 'deployer',
  :roles => %w(web app db),
  :ssh_options => {
    :forward_agent => true
  }
