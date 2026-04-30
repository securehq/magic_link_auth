module MagicLinkAuth
  module JwtAuthentication
    extend ActiveSupport::Concern

    included do
      before_action :authenticate_request
      attr_reader :current_user
    end

    class_methods do
      def skip_authentication(**options)
        skip_before_action :authenticate_request, **options
      end

      # Alias matching the host app's existing API: allow_unauthenticated_access
      def allow_unauthenticated_access(**options)
        skip_before_action :authenticate_request, **options
      end
    end

    private

      def authenticate_request
        token = extract_token
        if token.nil?
          render json: { error: "Authorization token required" }, status: :unauthorized
          return
        end

        claims = MagicLinkAuth::JsonWebToken.decode(token)
        if claims.nil?
          render json: { error: "Invalid or expired token" }, status: :unauthorized
          return
        end

        @current_user = MagicLinkAuth.user_class.find_by(id: claims[:user_id])
        if @current_user.nil?
          render json: { error: "User not found" }, status: :unauthorized
        end
      end

      def extract_token
        header = request.headers["Authorization"]
        header&.split(" ")&.last
      end
  end
end
