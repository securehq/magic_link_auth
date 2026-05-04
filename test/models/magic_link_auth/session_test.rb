# frozen_string_literal: true

require "test_helper"

class SessionTest < ActiveSupport::TestCase
  def setup
    @user = create_user
  end

  test "belongs to a user" do
    session = MagicLinkAuth::Session.create!(user: @user, ip_address: "127.0.0.1", user_agent: "TestAgent")
    assert_equal @user, session.user
  end

  test "persists ip_address and user_agent" do
    session = MagicLinkAuth::Session.create!(
      user: @user,
      ip_address: "192.168.1.1",
      user_agent: "Mozilla/5.0"
    )
    session.reload
    assert_equal "192.168.1.1", session.ip_address
    assert_equal "Mozilla/5.0", session.user_agent
  end

  test "ip_address and user_agent are optional" do
    session = MagicLinkAuth::Session.new(user: @user)
    assert session.valid?
  end

  test "a user can have many sessions" do
    MagicLinkAuth::Session.create!(user: @user, ip_address: "1.1.1.1")
    MagicLinkAuth::Session.create!(user: @user, ip_address: "2.2.2.2")
    assert_equal 2, @user.magic_link_sessions.count
  end

  test "destroying a user cascades to sessions" do
    MagicLinkAuth::Session.create!(user: @user)
    assert_difference "MagicLinkAuth::Session.count", -1 do
      @user.destroy
    end
  end
end
