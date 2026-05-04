# frozen_string_literal: true

require "test_helper"
require "rails/generators/test_case"
require "generators/magic_link_auth/install/install_generator"

class InstallGeneratorTest < Rails::Generators::TestCase
  tests MagicLinkAuth::Generators::InstallGenerator
  destination File.expand_path("../../tmp/generator_test", __dir__)
  setup :prepare_destination

  # --- Initializer ---

  test "copies the initializer to config/initializers/magic_link_auth.rb" do
    run_generator
    assert_file "config/initializers/magic_link_auth.rb"
  end

  test "initializer contains MagicLinkAuth.configure block" do
    run_generator
    assert_file "config/initializers/magic_link_auth.rb" do |content|
      assert_match(/MagicLinkAuth\.configure/, content)
    end
  end

  test "initializer contains user_class setting" do
    run_generator
    assert_file "config/initializers/magic_link_auth.rb" do |content|
      assert_match(/config\.user_class/, content)
    end
  end

  test "initializer contains jwt_secret setting" do
    run_generator
    assert_file "config/initializers/magic_link_auth.rb" do |content|
      assert_match(/config\.jwt_secret/, content)
    end
  end

  test "initializer contains session_cookie_name setting" do
    run_generator
    assert_file "config/initializers/magic_link_auth.rb" do |content|
      assert_match(/config\.session_cookie_name/, content)
    end
  end

  # --- Migrations ---

  test "copies the sessions migration" do
    run_generator
    assert_migration "db/migrate/create_magic_link_auth_sessions.rb"
  end

  test "copies the token denylists migration" do
    run_generator
    assert_migration "db/migrate/create_magic_link_auth_token_denylists.rb"
  end

  test "sessions migration creates the correct table" do
    run_generator
    assert_migration "db/migrate/create_magic_link_auth_sessions.rb" do |content|
      assert_match(/create_table :magic_link_auth_sessions/, content)
      assert_match(/t\.references :user/, content)
    end
  end

  test "token denylists migration creates the correct table with unique jti index" do
    run_generator
    assert_migration "db/migrate/create_magic_link_auth_token_denylists.rb" do |content|
      assert_match(/create_table :magic_link_auth_token_denylists/, content)
      assert_match(/t\.text :jti/, content)
      assert_match(/add_index.*:jti.*unique: true/, content)
    end
  end

  # --- Idempotency (second run should not overwrite) ---

  test "running the generator twice does not raise" do
    assert_nothing_raised do
      run_generator
      run_generator [], behavior: :skip
    end
  end
end
