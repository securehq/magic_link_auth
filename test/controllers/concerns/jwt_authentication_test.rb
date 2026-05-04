# frozen_string_literal: true

require "test_helper"

# Tests for MagicLinkAuth::JwtAuthentication concern
# exercised through the API sessions controller.
class MagicLinkAuth::JwtAuthenticationConcernTest < ActionDispatch::IntegrationTest
  def setup
    @user = create_user(email: "jwt_concern@example.com")
  end

  # authenticate_request runs on DELETE /auth/api/session (protected)

  test "missing Authorization header returns 401 with descriptive error" do
    delete magic_link_auth.api_session_path, as: :json
    assert_response :unauthorized
    assert_equal "Authorization token required", response.parsed_body["error"]
  end

  test "Authorization header with an invalid token returns 401" do
    delete magic_link_auth.api_session_path,
           headers: { "Authorization" => "Bearer invalid.token.value" },
           as: :json
    assert_response :unauthorized
    assert_equal "Invalid or expired token", response.parsed_body["error"]
  end

  test "Authorization header with an expired token returns 401" do
    expired_token = MagicLinkAuth::JsonWebToken.encode({ user_id: @user.id }, 1.second.ago)
    delete magic_link_auth.api_session_path,
           headers: { "Authorization" => "Bearer #{expired_token}" },
           as: :json
    assert_response :unauthorized
  end

  test "Authorization header with a denylisted token returns 401" do
    token = api_token_for(@user)
    MagicLinkAuth::JsonWebToken.denylist!(token)
    delete magic_link_auth.api_session_path,
           headers: { "Authorization" => "Bearer #{token}" },
           as: :json
    assert_response :unauthorized
  end

  test "Authorization header with a token for a non-existent user returns 401" do
    token = MagicLinkAuth::JsonWebToken.encode({ user_id: 999_999_999 })
    delete magic_link_auth.api_session_path,
           headers: { "Authorization" => "Bearer #{token}" },
           as: :json
    assert_response :unauthorized
    assert_equal "User not found", response.parsed_body["error"]
  end

  test "valid Bearer token allows the request through" do
    token = api_token_for(@user)
    delete magic_link_auth.api_session_path,
           headers: { "Authorization" => "Bearer #{token}" },
           as: :json
    assert_response :no_content
  end

  test "allow_unauthenticated_access skips authenticate_request for create" do
    # POST /auth/api/session has allow_unauthenticated_access — no token needed
    post magic_link_auth.api_session_path,
         params: { session: { email: @user.email } },
         as: :json
    assert_response :accepted
  end

  test "allow_unauthenticated_access skips authenticate_request for verify" do
    token = magic_link_token_for(@user)
    post magic_link_auth.verify_api_session_path,
         params: { session: { token: token } },
         as: :json
    assert_response :created
  end
end
