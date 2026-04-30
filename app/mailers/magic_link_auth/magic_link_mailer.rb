module MagicLinkAuth
  class MagicLinkMailer < ApplicationMailer
    # Sends a one-click sign-in email to +user+.
    # +token+ is a signed magic link JWT produced by MagicLinkAuth::JsonWebToken.encode_magic_link.
    def login_link(user, token)
      @user = user
      @app_name = MagicLinkAuth.configuration.app_name
      @magic_link_url = magic_link_auth.verify_session_url(token: token)

      config = MagicLinkAuth.configuration
      if config.deep_link_enabled?
        @app_link_url = "#{config.deep_link_scheme}://session/verify?token=#{token}"
      end

      mail(
        to: @user.email,
        subject: MagicLinkAuth.configuration.mailer_subject
      )
    end
  end
end
