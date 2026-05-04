# frozen_string_literal: true

require "test_helper"

class MagicLinkAuth::SessionsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create_user(email: "web_session@example.com")
    # Ensure deep link is disabled for most tests
    MagicLinkAuth.configuration.deep_link_scheme = nil
  end

  def teardown
    MagicLinkAuth.configuration.deep_link_scheme = nil
  end

  # --- GET /auth/session/new ---

  test "GET new renders the sign-in form" do
    get magic_link_auth.new_session_path
    assert_response :success
  end

  test "GET new is accessible without authentication" do
    get magic_link_auth.new_session_path
    assert_response :success
  end

  # --- POST /auth/session ---

  test "POST create with a valid email redirects to magic_link_sent" do
    post magic_link_auth.session_path, params: { email: @user.email }
    assert_redirected_to magic_link_auth.magic_link_sent_session_path
  end

  test "POST create with an unknown email still redirects to magic_link_sent (anti-enumeration)" do
    post magic_link_auth.session_path, params: { email: "unknown@example.com" }
    assert_redirected_to magic_link_auth.magic_link_sent_session_path
  end

  test "POST create with a valid email enqueues the magic link email" do
    assert_emails 1 do
      post magic_link_auth.session_path, params: { email: @user.email }
    end
  end

  test "POST create with an unknown email does NOT send an email" do
    assert_no_emails do
      post magic_link_auth.session_path, params: { email: "ghost@example.com" }
    end
  end

  # --- GET /auth/session/magic_link_sent ---

  test "GET magic_link_sent renders the confirmation page" do
    get magic_link_auth.magic_link_sent_session_path
    assert_response :success
  end

  # --- GET /auth/session/verify ---

  test "GET verify with a valid token creates a session and redirects" do
    token = magic_link_token_for(@user)
    get magic_link_auth.verify_session_path(token: token)
    assert_redirected_to "http://www.example.com/"
    assert_equal "Sign-in successful.", flash[:notice]
  end

  test "GET verify with a valid token sets the session cookie" do
    token = magic_link_token_for(@user)
    get magic_link_auth.verify_session_path(token: token)
    cookie_name = MagicLinkAuth.configuration.session_cookie_name
    assert cookies[cookie_name].present?
  end

  test "GET verify with an invalid token redirects to sign-in with alert" do
    get magic_link_auth.verify_session_path(token: "bad.token.value")
    assert_redirected_to magic_link_auth.new_session_path
    assert_equal "The sign-in link is invalid or has expired. Please request a new one.", flash[:alert]
  end

  test "GET verify with an expired token redirects to sign-in with alert" do
    expired_token = MagicLinkAuth::JsonWebToken.encode(
      { user_id: @user.id, purpose: "magic_link" },
      1.second.ago
    )
    get magic_link_auth.verify_session_path(token: expired_token)
    assert_redirected_to magic_link_auth.new_session_path
  end

  test "GET verify with a denylisted token redirects to sign-in" do
    token = magic_link_token_for(@user)
    MagicLinkAuth::JsonWebToken.denylist!(token)
    get magic_link_auth.verify_session_path(token: token)
    assert_redirected_to magic_link_auth.new_session_path
  end

  test "GET verify with a regular API token (no purpose) redirects to sign-in" do
    api_token = api_token_for(@user)
    get magic_link_auth.verify_session_path(token: api_token)
    assert_redirected_to magic_link_auth.new_session_path
  end

  test "GET verify renders open_in_app when deep_link_scheme is configured" do
    MagicLinkAuth.configuration.deep_link_scheme = "testapp"
    token = magic_link_token_for(@user)
    get magic_link_auth.verify_session_path(token: token)
    assert_response :success
    assert_match "testapp://session/verify?token=#{token}", response.body
  end

  # --- DELETE /auth/session ---

  test "DELETE destroy signs the user out and redirects to sign-in" do
    # First sign in
    token = magic_link_token_for(@user)
    get magic_link_auth.verify_session_path(token: token)

    delete magic_link_auth.session_path
    assert_redirected_to magic_link_auth.new_session_path
  end

  test "DELETE destroy clears the session cookie" do
    token = magic_link_token_for(@user)
    get magic_link_auth.verify_session_path(token: token)

    delete magic_link_auth.session_path
    cookie_name = MagicLinkAuth.configuration.session_cookie_name
    assert cookies[cookie_name].blank?
  end

  test "DELETE destroy removes the session record from the database" do
    token = magic_link_token_for(@user)
    get magic_link_auth.verify_session_path(token: token)

    assert_difference "MagicLinkAuth::Session.count", -1 do
      delete magic_link_auth.session_path
    end
  end
end
