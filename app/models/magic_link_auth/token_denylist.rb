module MagicLinkAuth
  class TokenDenylist < ActiveRecord::Base
    self.table_name = "magic_link_auth_token_denylists"

    validates :jti, presence: true, uniqueness: true
    validates :exp, presence: true

    scope :expired, -> { where("exp < ?", Time.current) }

    def self.denylisted?(jti)
      exists?(jti: jti)
    end

    def self.cleanup_expired!
      expired.delete_all
    end
  end
end
