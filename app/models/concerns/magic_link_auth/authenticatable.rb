module MagicLinkAuth
  module Authenticatable
    extend ActiveSupport::Concern

    included do
      has_many :magic_link_sessions,
               class_name: "MagicLinkAuth::Session",
               foreign_key: :user_id,
               dependent: :destroy

      normalizes :email, with: ->(e) { e.strip.downcase }
      validates :email, presence: true, uniqueness: { case_sensitive: false }
    end
  end
end
