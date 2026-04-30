module MagicLinkAuth
  class WellKnownController < ApplicationController
    allow_unauthenticated_access
    before_action :set_cache_headers
    before_action :ensure_deep_link_configured

    def apple_app_site_association
      config = MagicLinkAuth.configuration
      render json: {
        applinks: {
          apps: [],
          details: [
            {
              appIDs: [ config.ios_app_id ],
              components: [
                {
                  "/": "/session/verify*",
                  comment: "Magic link deep link for iOS"
                }
              ]
            }
          ]
        },
        webcredentials: {
          apps: [ config.ios_app_id ]
        }
      }
    end

    def assetlinks
      config = MagicLinkAuth.configuration
      render json: [
        {
          relation: [ "delegate_permission/common.handle_all_urls" ],
          target: {
            namespace: "android_app",
            package_name: config.android_package,
            sha256_cert_fingerprints: config.android_sha256_fingerprints
          }
        }
      ]
    end

    private

      def set_cache_headers
        expires_in 1.hour, public: true
      end

      def ensure_deep_link_configured
        head :not_found unless MagicLinkAuth.configuration.deep_link_enabled?
      end
  end
end
