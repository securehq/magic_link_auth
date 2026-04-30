module MagicLinkAuth
  module Api
    class SessionsController < Api::BaseController
      allow_unauthenticated_access only: %i[create verify]
      rate_limit to: 10, within: 3.minutes, only: :create,
                 with: -> { render json: { error: "Too many requests. Try again later." }, status: :too_many_requests }

      # POST /auth/api/session
      # Accepts an email and sends a magic link. Always returns 202 to prevent user enumeration.
      def create
        user = MagicLinkAuth.user_class.find_by(
          MagicLinkAuth.user_lookup_by => session_params[:email]
        )

        if user
          token = MagicLinkAuth::JsonWebToken.encode_magic_link(user.id)
          MagicLinkAuth::MagicLinkMailer.login_link(user, token).deliver_later
        end

        render json: { message: "If an account exists for that email, a sign-in link has been sent." },
               status: :accepted
      end

      # POST /auth/api/session/verify
      # Exchanges a magic link token for a long-lived API JWT.
      def verify
        token = verify_params[:token]
        claims = MagicLinkAuth::JsonWebToken.decode_magic_link(token)

        if claims.nil?
          render json: { error: "The sign-in link is invalid or has expired." }, status: :unprocessable_entity
          return
        end

        user = MagicLinkAuth.user_class.find_by(id: claims[:user_id])

        if user.nil?
          render json: { error: "The sign-in link is invalid or has expired." }, status: :unprocessable_entity
          return
        end

        # Single-use: denylist the magic link token before issuing the API token.
        MagicLinkAuth::JsonWebToken.denylist!(token)

        api_token = MagicLinkAuth::JsonWebToken.encode({ user_id: user.id })
        render json: { token: api_token }, status: :created
      end

      # DELETE /auth/api/session
      # Revokes the current Bearer token.
      def destroy
        bearer = extract_token
        MagicLinkAuth::JsonWebToken.denylist!(bearer) if bearer
        head :no_content
      end

      private

        def session_params
          params.require(:session).permit(:email)
        end

        def verify_params
          params.require(:session).permit(:token)
        end
    end
  end
end
