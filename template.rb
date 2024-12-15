# rubocop:disable all

require 'fileutils'
require 'shellwords'

# Copied from: https://github.com/mattbrictson/rails-template
# Add this template directory to source_paths so that Thor actions like
# copy_file and template resolve against our source files. If this file was
# invoked remotely via HTTP, that means the files are not present locally.
# In that case, use `git clone` to download them to a local temporary dir.
def add_template_repository_to_source_path
  if __FILE__ =~ %r{\Ahttps?://}
    require 'tmpdir'
    source_paths.unshift(tempdir = Dir.mktmpdir('rails-'))
    at_exit { FileUtils.remove_entry(tempdir) }
    git clone: [
      '--quiet',
      'https://github.com/dmunoz-10/rails-kickstarter.git',
      tempdir
    ].map(&:shellescape).join(' ')

    if (branch = __FILE__[%r{rails-kickstarter/(.+)/template.rb}, 1])
      Dir.chdir(tempdir) { git checkout: branch }
    end
  else
    source_paths.unshift(File.dirname(__FILE__))
  end
end

def add_development_and_test_gems
  gem_group :development, :test do
    gem 'awesome_print', '~> 1.9', '>= 1.9.2'
    gem 'dotenv-rails', '~> 3.1', '>= 3.1.4'
    gem 'factory_bot_rails', '~> 6.4', '>= 6.4.4'
    gem 'faker', '~> 3.5', '>= 3.5.1'
    gem 'rspec', '~> 3.13'
    gem 'rspec-rails', '~> 7.1'
    gem 'rswag-specs', '~> 2.16'
    gem 'rubocop-gitlab-security', require: false
    gem 'rubocop-rspec', require: false
    gem 'rubocop-rspec_rails', require: false
  end

  add_development_gems
  add_test_gems
end

def add_development_gems
  gem_group :development do
    gem 'annotaterb'
    gem 'better_errors', '~> 2.10', '>= 2.10.1'
    gem 'binding_of_caller', '~> 1.0', '>= 1.0.1'
    gem 'bullet', '~> 8.0'
    gem 'bundler-audit', '~> 0.9.2'
    gem 'database_consistency', '~> 1.7', '>= 1.7.26', require: false
    gem 'fasterer', '~> 0.11.0'
    gem 'js_from_routes', '~> 4.0', '>= 4.0.1'
    gem 'letter_opener_web', '~> 3.0'
    gem 'overcommit', '~> 0.64.1'
    gem 'rails_best_practices', '~> 1.23', '>= 1.23.2'
    gem 'reek', '~> 6.1', '>= 6.1.4'
    gem 'solargraph', '~> 0.50.0'
    gem 'solargraph-rails', '~> 1.1'
    gem 'sql_queries_count', '~> 0.0.1'
  end
end

def add_test_gems
  gem_group :test do
    gem 'fakeredis', '~> 0.9.2', require: 'fakeredis/rspec'
    gem 'json_matchers', '~> 0.11.1'
    gem 'rspec-sidekiq', '~> 5.0'
    gem 'rubycritic', '~> 4.9', '>= 4.9.1', require: false
    gem 'shoulda-callback-matchers', '~> 1.1', '>= 1.1.4'
    gem 'shoulda-matchers', '~> 6.4'
    gem 'simplecov', '~> 0.22.0', require: false
  end
end

def add_gems
  add_development_and_test_gems

  gem 'active_storage_validations', '~> 1.3', '>= 1.3.4'
  gem 'blueprinter', '~> 1.1', '>= 1.1.2'
  gem 'name_of_person', '~> 1.1', '>= 1.1.3'
  gem 'rswag-api', '~> 2.16'
  gem 'rswag-ui', '~> 2.16'
  gem 'sidekiq', '~> 7.3', '>= 7.3.6'
  gem 'turbo-rails'
  gem 'vite_rails', '~> 3.0', '>= 3.0.19'
end

def add_vite
  run 'bundle exec vite install'
  inject_into_file('vite.config.mts', "import FullReload from 'vite-plugin-full-reload'\n", after: %(from 'vite'\n))
  inject_into_file('vite.config.mts', "import StimulusHMR from 'vite-plugin-stimulus-hmr'\n", after: %(from 'vite'\n))
  inject_into_file('vite.config.mts', "\n    FullReload(['config/routes.rb', 'app/views/**/*']),", after: 'plugins: [')
  inject_into_file('vite.config.mts', "\n    StimulusHMR(),", after: 'plugins: [')
  append_to_file 'Procfile.dev', "worker: bundle exec sidekiq\n"
end

def add_javascript
  run 'yarn add local-time trix @rails/actiontext sass stimulus stimulus-vite-helpers vite-plugin-stimulus-hmr vite-plugin-full-reload typescript @js-from-routes/client'
end

def add_tailwindcss
  run 'yarn add -D tailwindcss @tailwindcss/forms @tailwindcss/typography @tailwindcss/aspect-ratio @tailwindcss/forms @tailwindcss/line-clamp autoprefixer eslint prettier eslint-plugin-prettier eslint-config-prettier eslint-plugin-tailwindcss path'
end

def add_annotate
  generate 'annotate_rb:install'
  gsub_file '.annotaterb.yml', ":routes: false\n", ":routes: true\n"
  gsub_file '.annotaterb.yml', ":sort: false\n", ":sort: true\n"
end

def add_bundler_audit
  config = <<~RUBY
    require 'bundler/audit/task'

    Bundler::Audit::Task.new
  RUBY

  inject_into_file 'Rakefile', "#{config}\n", after: %(require_relative "config/application"\n)
end

def add_overcommit
  run 'overcommit --install'
  run 'overcommit --sign'
  run 'overcommit --sign pre-commit'
end

def add_solargraph
  run 'solargraph config'
  config = <<~RUBY
    plugins:
      - solargraph-rails
  RUBY
  prepend_to_file('.solargraph.yml', "#{config}\n")
  # run 'bundle exec yard gems'
end

def add_rspec
  generate 'rspec:install'

  simplecov_config = <<~RUBY
    require 'simplecov'
    SimpleCov.start 'rails' do
      add_filter '/channels/application_cable/'
      add_filter '/mailers/'
      add_filter '/serializers/'
      add_filter 'controllers/application_controller.rb'
      add_group 'Policies', 'app/policies'
      add_group 'Services', 'app/services'
    end
  RUBY
  inject_into_file 'spec/rails_helper.rb', "#{simplecov_config}\n", after: %(require 'spec_helper'\n)

  config = <<-RUBY
  config.include FactoryBot::Syntax::Methods

  if Bullet.enable?
    config.before do
      Bullet.start_request
    end

    config.after do
      Bullet.perform_out_of_channel_notifications if Bullet.notification?
      Bullet.end_request
    end
  end

  Shoulda::Matchers.configure do |config|
    config.integrate do |with|
      with.test_framework :rspec
      with.library :rails
    end
  end

  ActiveStorage::Current.url_options = { host: ENV.fetch('DEFAULT_HOST') }
  RUBY
  inject_into_file(
    'spec/rails_helper.rb',
    "\n#{config}",
    after: %(  # config.filter_gems_from_backtrace("gem name")\n)
  )

  spec_helper_config = <<~RUBY
    require 'active_storage_validations/matchers'
    require 'json_matchers/rspec'
    require 'rspec-sidekiq'
  RUBY
  inject_into_file(
    'spec/spec_helper.rb',
    "#{spec_helper_config}\n",
    before: %(# This file was generated by the `rails generate rspec:install` command. Conventionally, all\n)
  )

  spec_helper_config2 = <<-RUBY
  config.include ActiveStorageValidations::Matchers

  JsonMatchers.schema_root = 'spec/support/api/schemas'

  RSpec::Sidekiq.configure do |config|
    # Clears all job queues before each example
    config.clear_all_enqueued_jobs = true

    # Whether to use terminal colours when outputting messages
    config.enable_terminal_colours = true

    # Warn when jobs are not enqueued to Redis but to a job array
    config.warn_when_jobs_not_processed_by_sidekiq = false
  end
  RUBY
  inject_into_file 'spec/spec_helper.rb', "\n#{spec_helper_config2}", after: "=end\n"
end

def add_rswag
  generate 'rswag:api:install'
  generate 'rswag:ui:install'
  run 'RAILS_ENV=test rails g rswag:specs:install'
  copy_file 'lib/tasks/rspec.rake', 'lib/tasks/rspec.rake'
  copy_file 'lib/tasks/rswag.rake', 'lib/tasks/rswag.rake'
  gsub_file 'config/initializers/rswag_ui.rb', 'swagger_endpoint', 'openapi_endpoint'
end

def add_sidekiq
  environment 'config.active_job.queue_adapter = :sidekiq'

  insert_into_file 'config/routes.rb',
                   "require 'sidekiq/web'\n\n",
                   before: 'Rails.application.routes.draw do'

  insert_into_file 'config/routes.rb',
                   "  mount Sidekiq::Web => '/sidekiq'\n\n",
                   after: "Rails.application.routes.draw do\n"
end

def add_letter_opener_web
  environment 'config.action_mailer.delivery_method = :letter_opener_web', env: 'development'

  insert_into_file 'config/routes.rb',
                   "\n  mount LetterOpenerWeb::Engine, at: '/letter_opener' if Rails.env.development?\n\n",
                   after: "Rails.application.routes.draw do\n"
end

def setup_gitignore
  config = <<~RUBY
    package-lock.json
    database_consistency_*
    .DS_Store
    dump.rdb
  RUBY
  append_to_file '.gitignore', "\n#{config}"
end

def copy_needed_files
  # Copy files that should always be in project
  copy_file '.database_consistency.yml', '.database_consistency.yml'
  copy_file '.fasterer.yml', '.fasterer.yml'
  copy_file '.overcommit.yml', '.overcommit.yml'
  copy_file '.reek.yml', '.reek.yml'
  rubocop_lints = File.read('.rubocop.yml', &:gets)
  append_into_file '.rubocop.yml', "\n#{rubocop_lints}\n"
  copy_file '.rubocop-security.yml', '.rubocop-security.yml'
  copy_file '.rubycritic.yml', '.rubycritic.yml'
  copy_file 'rails_best_practices.yml', 'rails_best_practices.yml'
  copy_file 'tsconfig.json', 'tsconfig.json'
end

def setup
  copy_needed_files

  setup_gitignore
  add_annotate
  add_bundler_audit
  add_letter_opener_web
  add_rspec
  add_rswag
  add_sidekiq
  add_solargraph
  rails_command 'active_storage:install'
  generate 'bullet:install'
  add_javascript
  add_vite
  add_tailwindcss
  rails_command 'turbo:install'
  rails_command 'js_from_routes:generate'
end

# Main setup
add_template_repository_to_source_path
add_gems

after_bundle do
  setup

  # Commit everything to git
  # unless ENV['SKIP_GIT']
  #   git :init
  #   git add: '.'
  #   # git commit will fail if user.email is not configured
  #   begin
  #     git commit: %(-m "Initial commit")
  #     add_overcommit
  #   rescue StandardError => e
  #     puts e.message
  #   end
  # end

  say
  say "#{app_name} app successfully created!", :blue
  say
  say "To get started with your new app:", :green
  say
  say "  cd #{app_name}"
  say
  say "  # Update config/database.yml with your database credentials"
  say
  say "  rails db:create && rails db:migrate"
  say "  gem install foreman"
  say "  foreman start # Run Rails, sidekiq, and vite"
end
