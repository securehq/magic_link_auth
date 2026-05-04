# frozen_string_literal: true

# Configure the dummy Rails application environment
ENV["RAILS_ENV"] ||= "test"

require File.expand_path("dummy/config/environment", __dir__)

# Explicitly load the dummy app models so they are accessible in tests
require File.expand_path("dummy/app/models/user", __dir__)
require File.expand_path("dummy/app/controllers/application_controller", __dir__)

# Manually set up the in-memory database BEFORE rails/test_help runs
# (which would otherwise try to run maintain_test_schema! against our
# custom database.yml and fail due to engine migration paths).
ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
load File.expand_path("dummy/db/schema.rb", __dir__)

# Prevent Rails from running its schema check — we loaded it manually above.
module ActiveRecord
  class Migration
    class << self
      def maintain_test_schema!
        # no-op: schema is managed by test/dummy/db/schema.rb loaded above
      end
    end
  end
end

# Load Rails testing helpers (after schema is set up and migration check disabled)
require "rails/test_help"
require "action_mailer/test_helper"

module ActiveSupport
  class TestCase
    # Wrap each test in a transaction and roll back after
    self.use_transactional_tests = true

    # Helper: create a persisted user for tests
    def create_user(email: "user@example.com")
      User.create!(email: email)
    end

    # Helper: generate a valid magic-link token for a user
    def magic_link_token_for(user)
      MagicLinkAuth::JsonWebToken.encode_magic_link(user.id)
    end

    # Helper: generate a valid API session token for a user
    def api_token_for(user)
      MagicLinkAuth::JsonWebToken.encode({ user_id: user.id })
    end
  end
end

# Integration tests use real HTTP requests which may go through separate DB connections.
# Use truncation strategy instead of transactions to ensure data is visible across connections.
class ActionDispatch::IntegrationTest
  self.use_transactional_tests = false

  teardown do
    # Clean up all test data after each integration test
    MagicLinkAuth::TokenDenylist.delete_all
    MagicLinkAuth::Session.delete_all
    User.delete_all
  end
end
