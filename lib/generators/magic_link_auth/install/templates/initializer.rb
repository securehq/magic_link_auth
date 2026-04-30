MagicLinkAuth.configure do |config|
  # The host app's user model class name.
  config.user_class = "User"

  # The attribute used to look up the user (must match a column on your users table).
  config.user_lookup_by = :email

  # HMAC-SHA256 secret for signing JWTs.
  # Falls back to Rails.application.credentials.api_jwt_secret if nil.
  config.jwt_secret = nil

  # How long a magic-link token is valid (single-use, expired on redemption).
  config.token_expiry = 15.minutes

  # How long the long-lived API JWT is valid.
  config.session_expiry = 7.days

  # Sender address for magic-link emails.
  # Falls back to ENV["MAILER_FROM"] or "no-reply@example.com" if nil.
  config.mailer_from = nil

  # Subject line of the magic-link email.
  config.mailer_subject = "Your sign-in link"

  # Application name used in email copy and page titles.
  config.app_name = "My App"

  # Custom URL scheme for native-app deep links (e.g. "myapp" → "myapp://session/verify?token=…").
  # Set to nil to disable deep-link support and hide the /.well-known routes.
  config.deep_link_scheme = nil

  # iOS App ID for /.well-known/apple-app-site-association (required when deep_link_scheme is set).
  # Format: "TEAMID.com.example.myapp"
  config.ios_app_id = nil

  # Android package name for /.well-known/assetlinks.json (required when deep_link_scheme is set).
  config.android_package = nil

  # SHA-256 certificate fingerprint(s) for Android App Links verification.
  config.android_sha256_fingerprints = []

  # Cookie name used to store the web session ID.
  config.session_cookie_name = "magic_link_session_id"
end
