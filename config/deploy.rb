# encoding: utf-8
# Custom - Config - Capistrano:

set :application, "canvas"
set :repo_url, 'git@git-repository'

# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }

set :deploy_via, :remote_cache
set :scm, :git
set :rvm_type, :user

# set :user, "deploy"
# set :use_sudo, true

set :format, :pretty
set :log_level, :debug
# set :pty, true

set :canvas_url, "https://my.app.com"

# Bundler - defaults in comments
# set :bundle_gemfile, -> { release_path.join('Gemfile') }

set :bundle_path, false
set :bundle_flags, '' # --quiet
set :bundle_without, "development test"
set :bundle_binstubs, false
# set :bundle_roles, :all

# Can also add "canvas_cdn", "newrelic", "saml_idp"...
yml_linked_files = ["amazon_s3", "cache_store", "database", "delayed_jobs", "dynamic_settings", "domain", "logging",
  "external_migration", "file_store", "outgoing_mail", "redis", "security"]
  .map{|f| "config/#{f}.yml"}
set :linked_files, yml_linked_files #+ ["config/GEM_HOME", ".ruby-version"]

set :linked_dirs, %w{log tmp/pids tmp/cache tmp/sockets tmp/files tmp/attachment_fu public/dist
    vendor/bundle public/system vendor/QTIMigrationTool}

# set :default_env, { rvm_bin_path: "~/.rvm/bin" } #path: "/opt/ruby/bin:$PATH" }
# set :keep_releases, 5

namespace :gems do

  desc 'Used to set different bundler vars based on server roles'
  task :set_bundler_vars do
    # on roles(:ubuntu) do
    #   within release_path do
    #     # execute "bundle config set deployment 'true'"
    #   end
    # end

    # on roles(:cent_os) do
    #   # set :bundle_flags, '--deployment'
    # end # --quiet --system

    on roles(:assets_sr) do
      # We normally need some dev packages to compile assets on the remote server
      set :bundle_without, false
    end
  end
end

namespace :deploy do
  task :start do; end;
  task :stop do; end;

  desc 'Signal Passenger to restart the application.'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      # Your restart mechanism here, for example:
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  desc 'Deprecated, will be replaced by a task using new systemd services'
  task :restart_delayed_jobs do
    on roles(:delayed_jobs), in: :sequence, wait: 5 do
      rvm_prefix = "#{fetch(:rvm_path)}/bin/rvm #{fetch(:rvm_ruby_version)} do"
      SSHKit.config.command_map.prefix[:service].unshift(rvm_prefix)
      within release_path do
        execute :service, "canvas_init restart"
        puts "\x1b[42m\x1b[1;37m Delayed jobs restarted! \x1b[0m"
      end
    end
  end

  task :set_deploy_path do
    on roles(:ubuntu) do
      set :deploy_to, "/opt/apps/#{fetch(:application)}"
    end
    # To deploy in a different location based on server role, for instance:
    # on roles(:cent_os) do
    #   set :deploy_to, "/opt/canvas/#{fetch(:application)}"
    # end
  end

  desc 'Simple task to upload some files to app servers in //'
  task :upload_file do
    on roles(:app), in: :parallel do |host|
      ask(:relative_file_path)
      file_path = fetch(:file_path)
      if !file_path.blank? && File.exists?(file_path)
        upload!(file_path)
      end
    end
  end

  #after :restart, :clear_cache do
  #  on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
  #  end
  #end
end

namespace :canvas do
  # REMOTE COMMANDS

  desc "Compile static assets"
  task :assets do
    on roles(:assets_sr), :on_error => :continue do
      execute "cd '#{release_path}'; RAILS_ENV=production JS_BUILD_NO_UGLIFY=true rake canvas:compile_assets"
    end
  end

  desc "Post-update commands"
  task :update_remote do
    on roles(:assets_sr), in: :parallel do |host|
      within release_path do
        with :rails_env => fetch(:rails_env) do
          rake "canvas:compile_assets RAILS_ENV=production JS_BUILD_NO_UGLIFY=true COMPILE_ASSETS_STYLEGUIDE=0"
          execute "cd '#{release_path}'; ./node_modules/.bin/gulp rev"
          rake "brand_configs:generate_and_upload_all RAILS_ENV=production" unless ENV["first_deploy"]
          #rake "canvas:cdn:upload_to_s3 RAILS_ENV=production"
        end
      end
    end

    puts "\x1b[42m\x1b[1;37m Assets precompiled! \x1b[0m"

    unless ENV["first_deploy"]
      on roles(:db), :on_error => :continue do
        within release_path do
          with :rails_env => fetch(:rails_env) do
            rake "db:load_notifications"
          end
        end
      end
    end

    puts "\x1b[42m\x1b[1;37m Update complete! \x1b[0m"
    puts "\x1b[42m\x1b[1;37m Don't forget to flush redis cache and restart server! \x1b[0m"
  end

  desc "Ping the canvas server to actually restart the app"
  task :ping do
    system "curl -m 10 #{fetch(:canvas_url)}/login"
  end

  # Install QTI Migration tools
  desc "Clone QTIMigrationTool - deprecated, ansible is handling this now"
  task :clone_qtimigrationtool do
    on roles(:web) do
      within "#{release_path}/vendor" do
        execute :git, "clone https://github.com/instructure/QTIMigrationTool.git QTIMigrationTool"
        execute :chmod, "+x QTIMigrationTool/migrate.py"
      end
    end
  end

  # Used to copy assets from assets_sr to assets_cp roles, if assets aren't pushed to S3
  task :get_assets do
    on roles(:assets_cp), in: :parallel do |host|
      puts host
      within release_path do
        cp_assets()
      end
    end
    puts "\x1b[42m\x1b[1;37m Assets successfully copied! \x1b[0m"
  end

  def cp_assets()
    fetch(:assets_folders).each do |folder|
      execute :rsync, "-azv --delete-after -e 'ssh -p #{fetch(:assets_cp_ssh_port)}' #{fetch(:assets_cp_ssh_user)}@#{fetch(:assets_source)}:#{fetch(:assets_source_path)}/#{folder} #{release_path}/public/"
    end
  end

end

before("deploy:starting", "deploy:set_deploy_path")
before("bundler:install", "gems:set_bundler_vars")
after("deploy:updating", "gems:config_bundler")
after("deploy:updated", "canvas:update_remote")

if ENV["first_deploy"]
  after("deploy:finished", "canvas:get_assets")
  after("deploy:finished", "deploy:restart")
  after("deploy:finished", "deploy:restart_delayed_jobs")
end
