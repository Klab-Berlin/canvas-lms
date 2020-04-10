# Custom - Config - Capistrano:
# Load DSL and Setup Up Stages
require 'capistrano/setup'

# Includes default deployment tasks
require 'capistrano/deploy'

# Includes tasks from other gems included in your Gemfile
#
# For documentation on these, see for example:
#
#   https://github.com/capistrano/rvm
#   https://github.com/capistrano/rbenv
#   https://github.com/capistrano/chruby
#   https://github.com/capistrano/bundler
#   https://github.com/capistrano/rails/tree/master/assets
#   https://github.com/capistrano/rails/tree/master/migrations
#

require 'capistrano/rvm'
require 'capistrano/bundler'
require 'capistrano/rails/migrations' unless ENV["first_deploy"] # Uncomment after first deploy

# Other requires
# require 'capistrano/rbenv'
# require 'capistrano/chruby'
# require 'capistrano/rails'
# require 'capistrano/rails/assets'

# From https://github.com/TalkingQuickly/capistrano-cookbook
require 'capistrano/cookbook/check_revision'
#require 'capistrano/cookbook/compile_assets_locally'
#require 'capistrano/cookbook/create_database'
require 'capistrano/cookbook/logs'
#require 'capistrano/cookbook/monit'
require 'capistrano/cookbook/nginx'
#require 'capistrano/cookbook/restart'
#require 'capistrano/cookbook/run_tests'
#require 'capistrano/cookbook/setup_config'

# Loads custom tasks from `lib/capistrano/tasks' if you have any defined.
Dir.glob('lib/capistrano/tasks/*.cap').each { |r| import r }
