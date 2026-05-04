require "rails"
require "active_model/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"

Bundler.require(*Rails.groups)
require "magic_link_auth"

module Dummy
  class Application < Rails::Application
    config.load_defaults Rails::VERSION::STRING.to_f

    config.eager_load = false

    config.action_mailer.delivery_method = :test
    config.action_mailer.default_url_options = { host: "example.com" }

    # Disable CSRF protection in tests
    config.action_controller.allow_forgery_protection = false

    # Use null cache store to prevent rate limiting from interfering with tests
    config.cache_store = :null_store

    # Use a simple secret key for tests
    config.secret_key_base = "test_secret_key_base_for_magic_link_auth_tests_only"

    # Disable host authorization checks in tests
    config.hosts.clear

    # Point the DB config to the dummy app's database.yml
    config.paths["config/database"] = [ File.expand_path("database.yml", __dir__) ]

    # Use the dummy app's routes file
    config.paths["config/routes.rb"] = [ File.expand_path("../routes.rb", __FILE__) ]

    # Load initializers from the dummy app
    config.paths["config/initializers"] = [ File.expand_path("initializers", __dir__) ]
  end
end
