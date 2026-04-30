module MagicLinkAuth
  class Session < ActiveRecord::Base
    self.table_name = "magic_link_auth_sessions"

    belongs_to :user, class_name: MagicLinkAuth.configuration.user_class, foreign_key: :user_id
  end
end
