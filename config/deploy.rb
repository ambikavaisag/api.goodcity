lock '3.11.0'

set :whenever_identifier, -> { "#{fetch(:application)}_#{fetch(:stage)}" }

set :application, 'goodcity_server'
set :repo_url, 'git@github.com:crossroads/api.goodcity.git'
set :deploy_to, '/opt/rails/goodcity_server'
set :linked_files, %w{ config/database.yml .env }
set :linked_dirs, %w{log tmp/pids tmp/cache}
set :bundle_binstubs, nil
set :rvm_ruby_version, '2.5.1'
set :rollbar_token, ENV['ROLLBAR_ACCESS_TOKEN']
set :rollbar_env, Proc.new { fetch :stage }
set :rollbar_role, Proc.new { :app }
set :newrelic_user, Proc.new { ENV['CIRCLE_USERNAME'] || ENV['USER'] }

after "deploy:updated", "newrelic:notice_deployment"

namespace :deploy do
  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end
  after :publishing, :restart
end

namespace :pg do
  desc "Bundle config setup for install 'pg' gem"
  task :config do
    on roles(:app) do
      within deploy_path do
        execute :bundle, "config build.pg --with-pg-config=/usr/pgsql-9.4/bin/pg_config"
      end
    end
  end
end

namespace :deploy do
  desc 'Testing stage value'
  task :testing_stage_value do
    puts "Stage variable value: #{stage}"
  end
end
