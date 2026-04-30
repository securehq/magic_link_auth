module MagicLinkAuth
  class Configuration
    # The class name (string) of the host app's user model.
    # Example: "User", "Account"
    attr_accessor :user_class

    # The attribute used to look up a user by their email address.
    attr_accessor :user_lookup_by

    # HMAC-SHA256 signing secret for all JWTs.
    # Defaults to Rails.application.credentials.api_jwt_secret.
    attr_accessor :jwt_secret

    # How long a magic-link token is valid.
    attr_accessor :token_expiry

    # How long the long-lived API JWT is valid.
    attr_accessor :session_expiry

    # Default "from" address used by MagicLinkMailer.
    attr_accessor :mailer_from

    # Email subject line for the magic-link email.
    attr_accessor :mailer_subject

    # Application name shown in email copy.
    attr_accessor :app_name

    # Custom URL scheme used to build the deep link in emails and the open_in_app view.
    # Set to nil to disable deep-link / well-known routes entirely.
    # Example: "myapp"  →  "myapp://session/verify?token=…"
    attr_accessor :deep_link_scheme

    # iOS App ID used in /.well-known/apple-app-site-association.
    # Example: "TEAMID.com.example.myapp"
    attr_accessor :ios_app_id

    # Android package name used in /.well-known/assetlinks.json.
    # Example: "com.example.myapp"
    attr_accessor :android_package

    # SHA-256 certificate fingerprint(s) for Android App Links verification.
    attr_accessor :android_sha256_fingerprints

    # Cookie name used to store the web session ID.
    attr_accessor :session_cookie_name

    def initialize
      @user_class = "User"
      @user_lookup_by = :email
      @jwt_secret = nil  # falls back to Rails.application.credentials.api_jwt_secret
      @token_expiry = 15.minutes
      @session_expiry = 7.days
      @mailer_from = nil  # falls back to ENV["MAILER_FROM"] or "no-reply@example.com"
      @mailer_subject = "Your sign-in link"
      @app_name = "My App"
      @deep_link_scheme = nil
      @ios_app_id = nil
      @android_package = nil
      @android_sha256_fingerprints = []
      @session_cookie_name = "magic_link_session_id"
    end

    def resolved_jwt_secret
      jwt_secret || Rails.application.credentials.api_jwt_secret
    end

    def resolved_mailer_from
      mailer_from || ENV.fetch("MAILER_FROM", "no-reply@example.com")
    end

    def deep_link_enabled?
      deep_link_scheme.present?
    end
  end
end
