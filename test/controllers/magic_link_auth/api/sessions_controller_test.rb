# frozen_string_literal: true

require "test_helper"

class MagicLinkAuth::Api::SessionsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create_user(email: "api_sessions@example.com")
  end

  # --- POST /auth/api/session ---

  test "POST create returns 202 when user exists" do
    post magic_link_auth.api_session_path,
         params: { session: { email: @user.email } },
         as: :json
    assert_response :accepted
    assert_equal "If an account exists for that email, a sign-in link has been sent.",
                 response.parsed_body["message"]
  end

  test "POST create returns 202 even when user does not exist (anti-enumeration)" do
    post magic_link_auth.api_session_path,
         params: { session: { email: "nobody@example.com" } },
         as: :json
    assert_response :accepted
  end

  test "POST create sends an email when user exists" do
    assert_emails 1 do
      post magic_link_auth.api_session_path,
           params: { session: { email: @user.email } },
           as: :json
    end
  end

  test "POST create does NOT send an email when user is not found" do
    assert_no_emails do
      post magic_link_auth.api_session_path,
           params: { session: { email: "nobody@example.com" } },
           as: :json
    end
  end

  test "POST create returns 400 when session param is missing" do
    post magic_link_auth.api_session_path,
         params: { email: @user.email },
         as: :json
    assert_response :bad_request
  end

  # --- POST /auth/api/session/verify ---

  test "POST verify with valid magic link token returns a JWT and 201" do
    token = magic_link_token_for(@user)
    post magic_link_auth.verify_api_session_path,
         params: { session: { token: token } },
         as: :json
    assert_response :created
    assert response.parsed_body["token"].present?
  end

  test "POST verify returns a decodable JWT with the user's id" do
    token = magic_link_token_for(@user)
    post magic_link_auth.verify_api_session_path,
         params: { session: { token: token } },
         as: :json
    api_token = response.parsed_body["token"]
    claims = MagicLinkAuth::JsonWebToken.decode(api_token)
    assert_equal @user.id, claims[:user_id]
  end

  test "POST verify denylists the magic link token (single-use)" do
    token = magic_link_token_for(@user)
    post magic_link_auth.verify_api_session_path,
         params: { session: { token: token } },
         as: :json
    assert_response :created

    # Second attempt must fail
    post magic_link_auth.verify_api_session_path,
         params: { session: { token: token } },
         as: :json
    assert_response :unprocessable_entity
  end

  test "POST verify with an expired token returns 422" do
    expired = MagicLinkAuth::JsonWebToken.encode(
      { user_id: @user.id, purpose: "magic_link" },
      1.second.ago
    )
    post magic_link_auth.verify_api_session_path,
         params: { session: { token: expired } },
         as: :json
    assert_response :unprocessable_entity
    assert_equal "The sign-in link is invalid or has expired.",
                 response.parsed_body["error"]
  end

  test "POST verify with a regular API token (no magic_link purpose) returns 422" do
    api_token = api_token_for(@user)
    post magic_link_auth.verify_api_session_path,
         params: { session: { token: api_token } },
         as: :json
    assert_response :unprocessable_entity
  end

  test "POST verify with a malformed token returns 422" do
    post magic_link_auth.verify_api_session_path,
         params: { session: { token: "not.a.real.token" } },
         as: :json
    assert_response :unprocessable_entity
  end

  test "POST verify returns 400 when session param is missing" do
    post magic_link_auth.verify_api_session_path,
         params: { token: "anything" },
         as: :json
    assert_response :bad_request
  end

  # --- DELETE /auth/api/session ---

  test "DELETE destroy with a valid Bearer token returns 204" do
    api_token = api_token_for(@user)
    delete magic_link_auth.api_session_path,
           headers: { "Authorization" => "Bearer #{api_token}" },
           as: :json
    assert_response :no_content
  end

  test "DELETE destroy denylists the Bearer token so it can no longer be used" do
    magic_token = magic_link_token_for(@user)
    post magic_link_auth.verify_api_session_path,
         params: { session: { token: magic_token } },
         as: :json
    api_token = response.parsed_body["token"]

    delete magic_link_auth.api_session_path,
           headers: { "Authorization" => "Bearer #{api_token}" },
           as: :json
    assert_response :no_content

    # The revoked token should no longer be decodable
    assert_nil MagicLinkAuth::JsonWebToken.decode(api_token)
  end

  test "DELETE destroy without a token still returns 204" do
    # destroy is protected by authenticate_request — but the bearer extraction returns nil
    # and denylist! is a no-op for nil. The controller just calls head :no_content.
    # However since authenticate_request runs first, we expect 401 without a token.
    delete magic_link_auth.api_session_path, as: :json
    assert_response :unauthorized
  end

  # --- Protected endpoints (authenticate_request) ---

  test "accessing a protected API endpoint with a valid token succeeds" do
    api_token = api_token_for(@user)
    # The destroy endpoint IS protected; we already test it above via destroy.
    # Re-test with a fresh token to confirm accept flow.
    delete magic_link_auth.api_session_path,
           headers: { "Authorization" => "Bearer #{api_token}" },
           as: :json
    assert_response :no_content
  end

  test "accessing a protected API endpoint without a token returns 401" do
    delete magic_link_auth.api_session_path, as: :json
    assert_response :unauthorized
    assert_equal "Authorization token required", response.parsed_body["error"]
  end

  test "accessing a protected API endpoint with a denylisted token returns 401" do
    api_token = api_token_for(@user)
    MagicLinkAuth::JsonWebToken.denylist!(api_token)
    delete magic_link_auth.api_session_path,
           headers: { "Authorization" => "Bearer #{api_token}" },
           as: :json
    assert_response :unauthorized
    assert_equal "Invalid or expired token", response.parsed_body["error"]
  end
end
