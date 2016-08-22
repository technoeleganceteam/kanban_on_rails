# config valid only for current version of Capistrano
lock '3.5.0'

set :application, 'kanbanonrails'
set :repo_url, Settings.git_repository

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, '/home/deployer/kanbanonrails'

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: 'log/capistrano.log', color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
set :linked_files, fetch(:linked_files) { [] }.push('config/settings.local.yml')

# Default value for linked_dirs is []
set :linked_dirs, fetch(:linked_dirs) { [] }.push('bin', 'log', 'tmp/pids',
  'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system', 'public/assets')

set :bundle_binstubs, -> { shared_path.join('bin') }

# set :passenger_in_gemfile, true
set :passenger_rvm_ruby_version, fetch(:rvm_ruby_version)
# set :passenger_restart_options

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

namespace :deploy do
  after :restart, :clear_cache do
    on roles(:web), :in => :groups, :limit => 3, :wait => 10 do
      within release_path do
        execute :rake, 'memcached:flush'
      end
    end
  end
end
