# frozen_string_literal: true

require "test_helper"

class AuthenticatableTest < ActiveSupport::TestCase
  # --- Email normalization ---

  test "strips leading and trailing whitespace from email" do
    user = User.create!(email: "  user@example.com  ")
    assert_equal "user@example.com", user.email
  end

  test "downcases email" do
    user = User.create!(email: "User@EXAMPLE.COM")
    assert_equal "user@example.com", user.email
  end

  test "strips and downcases email together" do
    user = User.create!(email: "  UPPER@Example.Com  ")
    assert_equal "upper@example.com", user.email
  end

  # --- Validations ---

  test "requires email" do
    user = User.new(email: "")
    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test "requires unique email" do
    User.create!(email: "unique@example.com")
    duplicate = User.new(email: "unique@example.com")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email], "has already been taken"
  end

  test "uniqueness check is case-insensitive" do
    User.create!(email: "test@example.com")
    # After normalization both become the same lowercase value
    duplicate = User.new(email: "TEST@EXAMPLE.COM")
    assert_not duplicate.valid?
  end

  test "valid user with proper email" do
    user = User.new(email: "valid@example.com")
    assert user.valid?
  end

  # --- Associations ---

  test "has many magic_link_sessions" do
    user = create_user(email: "sessions_test@example.com")
    MagicLinkAuth::Session.create!(user: user)
    assert_equal 1, user.magic_link_sessions.count
    assert_kind_of MagicLinkAuth::Session, user.magic_link_sessions.first
  end

  test "magic_link_sessions are destroyed with the user" do
    user = create_user(email: "cascade@example.com")
    MagicLinkAuth::Session.create!(user: user)

    assert_difference "MagicLinkAuth::Session.count", -1 do
      user.destroy
    end
  end
end
