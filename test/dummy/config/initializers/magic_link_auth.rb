MagicLinkAuth.configure do |config|
  config.user_class = "User"
  config.user_lookup_by = :email
  config.jwt_secret = "test_jwt_secret_for_magic_link_auth_tests_only_xxxxxxx"
  config.token_expiry = 15.minutes
  config.session_expiry = 7.days
  config.app_name = "Test App"
  config.mailer_from = "no-reply@test.com"
  config.mailer_subject = "Your sign-in link"
end
