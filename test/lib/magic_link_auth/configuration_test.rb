# frozen_string_literal: true

require "test_helper"

class ConfigurationTest < ActiveSupport::TestCase
  def setup
    @config = MagicLinkAuth::Configuration.new
  end

  # --- Defaults ---

  test "default user_class is 'User'" do
    assert_equal "User", @config.user_class
  end

  test "default user_lookup_by is :email" do
    assert_equal :email, @config.user_lookup_by
  end

  test "default jwt_secret is nil" do
    assert_nil @config.jwt_secret
  end

  test "default token_expiry is 15 minutes" do
    assert_equal 15.minutes, @config.token_expiry
  end

  test "default session_expiry is 7 days" do
    assert_equal 7.days, @config.session_expiry
  end

  test "default mailer_from is nil" do
    assert_nil @config.mailer_from
  end

  test "default mailer_subject is 'Your sign-in link'" do
    assert_equal "Your sign-in link", @config.mailer_subject
  end

  test "default app_name is 'My App'" do
    assert_equal "My App", @config.app_name
  end

  test "default deep_link_scheme is nil" do
    assert_nil @config.deep_link_scheme
  end

  test "default session_cookie_name is 'magic_link_session_id'" do
    assert_equal "magic_link_session_id", @config.session_cookie_name
  end

  test "default android_sha256_fingerprints is an empty array" do
    assert_equal [], @config.android_sha256_fingerprints
  end

  # --- resolved_jwt_secret ---

  test "resolved_jwt_secret returns jwt_secret when set" do
    @config.jwt_secret = "my_explicit_secret"
    assert_equal "my_explicit_secret", @config.resolved_jwt_secret
  end

  test "resolved_jwt_secret falls back to Rails credentials when jwt_secret is nil" do
    @config.jwt_secret = nil
    # In the test dummy app, credentials.api_jwt_secret may be nil
    # We just verify it doesn't raise
    assert_nothing_raised { @config.resolved_jwt_secret }
  end

  # --- resolved_mailer_from ---

  test "resolved_mailer_from returns mailer_from when set" do
    @config.mailer_from = "custom@example.com"
    assert_equal "custom@example.com", @config.resolved_mailer_from
  end

  test "resolved_mailer_from falls back to MAILER_FROM env var" do
    @config.mailer_from = nil
    original = ENV["MAILER_FROM"]
    ENV["MAILER_FROM"] = "env@example.com"
    assert_equal "env@example.com", @config.resolved_mailer_from
  ensure
    ENV["MAILER_FROM"] = original
  end

  test "resolved_mailer_from defaults to no-reply@example.com" do
    @config.mailer_from = nil
    original = ENV["MAILER_FROM"]
    ENV.delete("MAILER_FROM")
    assert_equal "no-reply@example.com", @config.resolved_mailer_from
  ensure
    ENV["MAILER_FROM"] = original
  end

  # --- deep_link_enabled? ---

  test "deep_link_enabled? is false when deep_link_scheme is nil" do
    @config.deep_link_scheme = nil
    assert_not @config.deep_link_enabled?
  end

  test "deep_link_enabled? is false when deep_link_scheme is empty string" do
    @config.deep_link_scheme = ""
    assert_not @config.deep_link_enabled?
  end

  test "deep_link_enabled? is true when deep_link_scheme is set" do
    @config.deep_link_scheme = "myapp"
    assert @config.deep_link_enabled?
  end

  # --- MagicLinkAuth.configure DSL ---

  test "configure yields the configuration object" do
    yielded = nil
    MagicLinkAuth.configure { |c| yielded = c }
    assert_equal MagicLinkAuth.configuration, yielded
  end

  test "configure allows setting multiple options" do
    original_name = MagicLinkAuth.configuration.app_name
    MagicLinkAuth.configure do |c|
      c.app_name = "New Name"
      c.mailer_subject = "New Subject"
    end
    assert_equal "New Name", MagicLinkAuth.configuration.app_name
    assert_equal "New Subject", MagicLinkAuth.configuration.mailer_subject
  ensure
    MagicLinkAuth.configuration.app_name = original_name
    MagicLinkAuth.configuration.mailer_subject = "Your sign-in link"
  end
end
