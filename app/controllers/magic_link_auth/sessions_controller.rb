module MagicLinkAuth
  class SessionsController < ApplicationController
    allow_unauthenticated_access only: %i[new create verify magic_link_sent]
    rate_limit to: 10, within: 3.minutes, only: :create,
               with: -> { redirect_to magic_link_auth.new_session_path, alert: "Try again later." }

    def new
    end

    # POST /auth/session
    # Accepts an email address, looks up (or ignores missing) the user, and delivers
    # a magic link. Always responds the same way to prevent user enumeration.
    def create
      user = MagicLinkAuth.user_class.find_by(
        MagicLinkAuth.user_lookup_by => params[:email]
      )

      if user
        token = MagicLinkAuth::JsonWebToken.encode_magic_link(user.id)
        MagicLinkAuth::MagicLinkMailer.login_link(user, token).deliver_later
      end

      redirect_to magic_link_auth.magic_link_sent_session_path
    end

    # GET /auth/session/verify?token=…
    # Validates the token and renders the deep-link redirect page.
    # Does NOT consume the token — that is done by the API verify endpoint.
    def verify
      token = params[:token]
      claims = MagicLinkAuth::JsonWebToken.decode_magic_link(token)

      if claims.nil?
        redirect_to magic_link_auth.new_session_path,
                    alert: "The sign-in link is invalid or has expired. Please request a new one."
        return
      end

      config = MagicLinkAuth.configuration
      if config.deep_link_enabled?
        @app_deep_link = "#{config.deep_link_scheme}://session/verify?token=#{token}"
        render :open_in_app
      else
        user = MagicLinkAuth.user_class.find_by(id: claims["user_id"])
        start_new_session_for(user)

        redirect_to after_authentication_url, notice: "Sign-in successful."
      end
    end

    # GET /auth/session/magic_link_sent
    def magic_link_sent
    end

    # DELETE /auth/session
    def destroy
      terminate_session
      redirect_to magic_link_auth.new_session_path
    end
  end
end
