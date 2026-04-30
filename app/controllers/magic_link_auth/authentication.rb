module MagicLinkAuth
  module Authentication
    extend ActiveSupport::Concern

    included do
      before_action :require_authentication
      helper_method :authenticated?
    end

    class_methods do
      def allow_unauthenticated_access(**options)
        skip_before_action :require_authentication, **options
      end
    end

    private

      def authenticated?
        resume_session
      end

      def require_authentication
        resume_session || request_authentication
      end

      def resume_session
        MagicLinkAuth::Current.session ||= find_session_by_cookie
      end

      def find_session_by_cookie
        cookie_name = MagicLinkAuth.configuration.session_cookie_name
        MagicLinkAuth::Session.find_by(id: cookies.signed[cookie_name]) if cookies.signed[cookie_name]
      end

      def request_authentication
        session[:return_to_after_authenticating] = request.url
        redirect_to magic_link_auth.new_session_path
      end

      def after_authentication_url
        session.delete(:return_to_after_authenticating) || main_app.root_url
      end

      def start_new_session_for(user)
        cookie_name = MagicLinkAuth.configuration.session_cookie_name
        user.magic_link_sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |s|
          MagicLinkAuth::Current.session = s
          cookies.signed.permanent[cookie_name] = { value: s.id, httponly: true, same_site: :lax }
        end
      end

      def terminate_session
        cookie_name = MagicLinkAuth.configuration.session_cookie_name
        MagicLinkAuth::Current.session.destroy
        cookies.delete(cookie_name)
      end
  end
end
