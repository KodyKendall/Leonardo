# NOTE: Saving this file because this appears to be working to run a separate capybara server, and it actually attempts to run. This is on RSB's remote server, and it's actually running.
# d02678cbbab8   kody06/llamapress-simple:0.2.6a   "bash -c 'rm -f tmp/…"   2 hours ago   Up 2 hours            0.0.0.0:3000->3000/tcp, [::]:3000->3000/tcp   leonardo-llamapress-1
# f31acef9dc1f   kody06/llamabot:0.3.0a            "bash -c 'python ini…"   2 hours ago   Up 2 hours            0.0.0.0:8080->8000/tcp, [::]:8080->8000/tcp   leonardo-llamabot-1

require 'spec_helper'
ENV['RAILS_ENV'] = 'test' # Force into test environment so we don't destroy dev or prod data
require_relative '../config/environment'
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'
require 'capybara/rspec'
require 'capybara/cuprite'
require 'database_cleaner/active_record'
require 'shoulda-matchers'

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

Capybara.register_driver(:cuprite) do |app|
  Capybara::Cuprite::Driver.new(
    app,
    window_size: [1400, 1400],
    browser_options: {
      'no-sandbox' => nil,
      'disable-gpu' => nil,
      'disable-dev-shm-usage' => nil
    },
    process_timeout: 30,
    timeout: 15,
    inspector: ENV['INSPECTOR'] == 'true',
    headless: !ENV['HEADLESS']&.match?(/^(false|no|0)$/i)
  )
end

Capybara.default_driver = :rack_test
Capybara.javascript_driver = :cuprite

RSpec.configure do |config|
  config.fixture_paths = [Rails.root.join('spec/fixtures')]
  config.use_transactional_fixtures = false
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  config.include FactoryBot::Syntax::Methods
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include Devise::Test::IntegrationHelpers, type: :system
  config.include Devise::Test::ControllerHelpers, type: :view
  config.include ActionDispatch::TestProcess::FixtureFile
  config.include Warden::Test::Helpers, type: :feature
  config.include ActiveSupport::Testing::TimeHelpers


  config.before(:suite) do
    # Allow DatabaseCleaner to work with DATABASE_URL (Docker environments)
    DatabaseCleaner.allow_remote_database_url = true
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, type: :system) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each, type: :feature) do
    DatabaseCleaner.strategy = :truncation
  end

  # Disable CSRF protection in request tests
  config.before(:each, type: :request) do
    allow_any_instance_of(ActionController::Base).to receive(:verify_authenticity_token).and_return(true)
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
