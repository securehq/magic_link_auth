require "magic_link_auth/version"
require "magic_link_auth/configuration"
require "magic_link_auth/engine"
require "magic_link_auth/json_web_token"

module MagicLinkAuth
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield configuration
    end

    # Convenience delegators
    def user_class
      configuration.user_class.constantize
    end

    def user_lookup_by
      configuration.user_lookup_by
    end
  end
end
