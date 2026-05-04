# frozen_string_literal: true

require "test_helper"

class TokenDenylistTest < ActiveSupport::TestCase
  def setup
    @jti = SecureRandom.uuid
    @exp = 1.hour.from_now
  end

  # --- Validations ---

  test "is valid with jti and exp" do
    record = MagicLinkAuth::TokenDenylist.new(jti: @jti, exp: @exp)
    assert record.valid?
  end

  test "requires jti" do
    record = MagicLinkAuth::TokenDenylist.new(exp: @exp)
    assert_not record.valid?
    assert_includes record.errors[:jti], "can't be blank"
  end

  test "requires exp" do
    record = MagicLinkAuth::TokenDenylist.new(jti: @jti)
    assert_not record.valid?
    assert_includes record.errors[:exp], "can't be blank"
  end

  test "enforces uniqueness on jti" do
    MagicLinkAuth::TokenDenylist.create!(jti: @jti, exp: @exp)
    duplicate = MagicLinkAuth::TokenDenylist.new(jti: @jti, exp: @exp)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:jti], "has already been taken"
  end

  # --- .denylisted? ---

  test ".denylisted? returns false when jti is not in the list" do
    assert_not MagicLinkAuth::TokenDenylist.denylisted?(@jti)
  end

  test ".denylisted? returns true when jti exists" do
    MagicLinkAuth::TokenDenylist.create!(jti: @jti, exp: @exp)
    assert MagicLinkAuth::TokenDenylist.denylisted?(@jti)
  end

  # --- .cleanup_expired! ---

  test ".cleanup_expired! removes records whose exp is in the past" do
    MagicLinkAuth::TokenDenylist.create!(jti: @jti, exp: 1.second.ago)
    other_jti = SecureRandom.uuid
    MagicLinkAuth::TokenDenylist.create!(jti: other_jti, exp: 1.hour.from_now)

    assert_difference "MagicLinkAuth::TokenDenylist.count", -1 do
      MagicLinkAuth::TokenDenylist.cleanup_expired!
    end

    assert_not MagicLinkAuth::TokenDenylist.denylisted?(@jti)
    assert MagicLinkAuth::TokenDenylist.denylisted?(other_jti)
  end

  test ".cleanup_expired! does nothing when no tokens are expired" do
    MagicLinkAuth::TokenDenylist.create!(jti: @jti, exp: 1.hour.from_now)

    assert_no_difference "MagicLinkAuth::TokenDenylist.count" do
      MagicLinkAuth::TokenDenylist.cleanup_expired!
    end
  end

  test ".cleanup_expired! returns 0 when table is empty" do
    deleted = MagicLinkAuth::TokenDenylist.cleanup_expired!
    assert_equal 0, deleted
  end

  # --- expired scope ---

  test "expired scope returns only expired records" do
    MagicLinkAuth::TokenDenylist.create!(jti: SecureRandom.uuid, exp: 1.minute.ago)
    MagicLinkAuth::TokenDenylist.create!(jti: SecureRandom.uuid, exp: 1.minute.from_now)

    assert_equal 1, MagicLinkAuth::TokenDenylist.expired.count
  end
end
