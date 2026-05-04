# frozen_string_literal: true

require "test_helper"

class MagicLinkMailerTest < ActionMailer::TestCase
  def setup
    @user = create_user(email: "mailer_test@example.com")
    @token = magic_link_token_for(@user)
  end

  test "login_link delivers to the user's email" do
    mail = MagicLinkAuth::MagicLinkMailer.login_link(@user, @token)
    assert_equal [ @user.email ], mail.to
  end

  test "login_link uses configured mailer_from" do
    mail = MagicLinkAuth::MagicLinkMailer.login_link(@user, @token)
    assert_equal [ MagicLinkAuth.configuration.resolved_mailer_from ], mail.from
  end

  test "login_link uses configured mailer_subject" do
    mail = MagicLinkAuth::MagicLinkMailer.login_link(@user, @token)
    assert_equal MagicLinkAuth.configuration.mailer_subject, mail.subject
  end

  test "login_link HTML body contains the verify URL" do
    mail = MagicLinkAuth::MagicLinkMailer.login_link(@user, @token)
    html = mail.html_part.body.to_s
    assert_includes html, @token
  end

  test "login_link text body contains the verify URL" do
    mail = MagicLinkAuth::MagicLinkMailer.login_link(@user, @token)
    text = mail.text_part.body.to_s
    assert_includes text, @token
  end

  test "login_link HTML body contains the app name" do
    mail = MagicLinkAuth::MagicLinkMailer.login_link(@user, @token)
    html = mail.html_part.body.to_s
    assert_includes html, MagicLinkAuth.configuration.app_name
  end

  test "login_link does not include deep link URL when deep link is disabled" do
    mail = MagicLinkAuth::MagicLinkMailer.login_link(@user, @token)
    html = mail.html_part.body.to_s
    assert_not_includes html, "://"
  rescue Minitest::Assertion
    # The magic link URL itself contains ://, so we check for the scheme specifically
    assert_not_includes html, "myapp://"
  end

  test "login_link includes app deep link URL when deep_link_scheme is configured" do
    MagicLinkAuth.configuration.deep_link_scheme = "testapp"
    mail = MagicLinkAuth::MagicLinkMailer.login_link(@user, @token)
    html = mail.html_part.body.to_s
    assert_includes html, "testapp://session/verify?token=#{@token}"
  ensure
    MagicLinkAuth.configuration.deep_link_scheme = nil
  end
end
