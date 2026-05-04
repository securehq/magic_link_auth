# frozen_string_literal: true

require "test_helper"

class JsonWebTokenTest < ActiveSupport::TestCase
  def setup
    # Ensure we start with a clean denylist
    MagicLinkAuth::TokenDenylist.delete_all
    @user = create_user
  end

  # --- encode ---

  test "encode returns a non-empty string token" do
    token = MagicLinkAuth::JsonWebToken.encode({ user_id: @user.id })
    assert_kind_of String, token
    assert_not_empty token
  end

  test "encode embeds a jti claim" do
    token = MagicLinkAuth::JsonWebToken.encode({ user_id: @user.id })
    decoded = JWT.decode(token, MagicLinkAuth.configuration.resolved_jwt_secret, true, algorithm: "HS256").first
    assert decoded["jti"].present?
  end

  test "encode embeds an exp claim in the future" do
    token = MagicLinkAuth::JsonWebToken.encode({ user_id: @user.id })
    decoded = JWT.decode(token, MagicLinkAuth.configuration.resolved_jwt_secret, true, algorithm: "HS256").first
    assert decoded["exp"] > Time.current.to_i
  end

  test "encode respects a custom expiry" do
    exp = 1.hour.from_now
    token = MagicLinkAuth::JsonWebToken.encode({ user_id: @user.id }, exp)
    decoded = JWT.decode(token, MagicLinkAuth.configuration.resolved_jwt_secret, true, algorithm: "HS256").first
    assert_in_delta exp.to_i, decoded["exp"], 2
  end

  # --- decode ---

  test "decode returns a HashWithIndifferentAccess for valid token" do
    token = MagicLinkAuth::JsonWebToken.encode({ user_id: @user.id })
    claims = MagicLinkAuth::JsonWebToken.decode(token)
    assert_kind_of HashWithIndifferentAccess, claims
    assert_equal @user.id, claims[:user_id]
    assert_equal @user.id, claims["user_id"]
  end

  test "decode returns nil for a malformed token" do
    assert_nil MagicLinkAuth::JsonWebToken.decode("not.a.jwt")
  end

  test "decode returns nil for a token signed with a different secret" do
    wrong_token = JWT.encode({ user_id: @user.id }, "wrong_secret", "HS256")
    assert_nil MagicLinkAuth::JsonWebToken.decode(wrong_token)
  end

  test "decode returns nil for an expired token" do
    token = MagicLinkAuth::JsonWebToken.encode({ user_id: @user.id }, 1.second.ago)
    assert_nil MagicLinkAuth::JsonWebToken.decode(token)
  end

  test "decode returns nil when the jti is denylisted" do
    token = MagicLinkAuth::JsonWebToken.encode({ user_id: @user.id })
    MagicLinkAuth::JsonWebToken.denylist!(token)
    assert_nil MagicLinkAuth::JsonWebToken.decode(token)
  end

  # --- denylist! ---

  test "denylist! creates a TokenDenylist record" do
    token = MagicLinkAuth::JsonWebToken.encode({ user_id: @user.id })
    assert_difference "MagicLinkAuth::TokenDenylist.count", 1 do
      MagicLinkAuth::JsonWebToken.denylist!(token)
    end
  end

  test "denylist! returns nil gracefully for a malformed token" do
    assert_nil MagicLinkAuth::JsonWebToken.denylist!("bad.token.here")
  end

  test "denylist! returns nil gracefully for an expired token" do
    token = MagicLinkAuth::JsonWebToken.encode({ user_id: @user.id }, 1.second.ago)
    assert_nil MagicLinkAuth::JsonWebToken.denylist!(token)
  end

  # --- encode_magic_link ---

  test "encode_magic_link returns a token with purpose=magic_link" do
    token = MagicLinkAuth::JsonWebToken.encode_magic_link(@user.id)
    decoded = JWT.decode(token, MagicLinkAuth.configuration.resolved_jwt_secret, true, algorithm: "HS256").first
    assert_equal "magic_link", decoded["purpose"]
  end

  test "encode_magic_link embeds the user_id" do
    token = MagicLinkAuth::JsonWebToken.encode_magic_link(@user.id)
    decoded = JWT.decode(token, MagicLinkAuth.configuration.resolved_jwt_secret, true, algorithm: "HS256").first
    assert_equal @user.id, decoded["user_id"]
  end

  test "encode_magic_link uses token_expiry from config" do
    token = MagicLinkAuth::JsonWebToken.encode_magic_link(@user.id)
    decoded = JWT.decode(token, MagicLinkAuth.configuration.resolved_jwt_secret, true, algorithm: "HS256").first
    expected_exp = MagicLinkAuth.configuration.token_expiry.from_now.to_i
    assert_in_delta expected_exp, decoded["exp"], 5
  end

  # --- decode_magic_link ---

  test "decode_magic_link returns claims for a valid magic link token" do
    token = MagicLinkAuth::JsonWebToken.encode_magic_link(@user.id)
    claims = MagicLinkAuth::JsonWebToken.decode_magic_link(token)
    assert_not_nil claims
    assert_equal @user.id, claims[:user_id]
  end

  test "decode_magic_link returns nil for a regular API token (no purpose claim)" do
    token = MagicLinkAuth::JsonWebToken.encode({ user_id: @user.id })
    assert_nil MagicLinkAuth::JsonWebToken.decode_magic_link(token)
  end

  test "decode_magic_link returns nil for a token with wrong purpose" do
    token = MagicLinkAuth::JsonWebToken.encode({ user_id: @user.id, purpose: "other" })
    assert_nil MagicLinkAuth::JsonWebToken.decode_magic_link(token)
  end

  test "decode_magic_link returns nil for a denylisted token" do
    token = MagicLinkAuth::JsonWebToken.encode_magic_link(@user.id)
    MagicLinkAuth::JsonWebToken.denylist!(token)
    assert_nil MagicLinkAuth::JsonWebToken.decode_magic_link(token)
  end

  test "decode_magic_link returns nil for an expired token" do
    token = MagicLinkAuth::JsonWebToken.encode(
      { user_id: @user.id, purpose: "magic_link" },
      1.second.ago
    )
    assert_nil MagicLinkAuth::JsonWebToken.decode_magic_link(token)
  end

  test "decode_magic_link returns nil for a malformed token" do
    assert_nil MagicLinkAuth::JsonWebToken.decode_magic_link("garbage")
  end
end
