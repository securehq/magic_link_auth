module MagicLinkAuth
  class Engine < ::Rails::Engine
    isolate_namespace MagicLinkAuth

    config.generators do |g|
      g.test_framework nil
    end

    initializer "magic_link_auth.action_mailer" do
      ActiveSupport.on_load(:action_mailer) do
        MagicLinkAuth::ApplicationMailer.default(
          from: -> { MagicLinkAuth.configuration.resolved_mailer_from }
        )
      end
    end
  end
end
