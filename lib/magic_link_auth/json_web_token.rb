module MagicLinkAuth
  class JsonWebToken
    MAGIC_LINK_PURPOSE = "magic_link"

    def self.config
      MagicLinkAuth.configuration
    end

    def self.secret_key
      config.resolved_jwt_secret
    end

    def self.encode(payload, exp = nil)
      exp ||= config.session_expiry.from_now
      payload = payload.dup
      payload[:exp] = exp.to_i
      payload[:iat] = Time.current.to_i
      payload[:jti] = SecureRandom.uuid
      JWT.encode(payload, secret_key, "HS256")
    end

    def self.decode(token)
      decoded = JWT.decode(token, secret_key, true, algorithm: "HS256")
      claims = HashWithIndifferentAccess.new(decoded.first)

      return nil if MagicLinkAuth::TokenDenylist.denylisted?(claims[:jti])

      claims
    rescue JWT::DecodeError, JWT::ExpiredSignature
      nil
    end

    def self.denylist!(token)
      claims = JWT.decode(token, secret_key, true, algorithm: "HS256").first
      MagicLinkAuth::TokenDenylist.create!(
        jti: claims["jti"],
        exp: Time.at(claims["exp"])
      )
    rescue JWT::DecodeError, JWT::ExpiredSignature
      nil
    end

    # Encodes a short-lived, single-use magic link token for the given user.
    # The token carries a +purpose+ claim to prevent reuse as a regular API token.
    def self.encode_magic_link(user_id)
      encode({ user_id: user_id, purpose: MAGIC_LINK_PURPOSE }, config.token_expiry.from_now)
    end

    # Decodes a magic link token. Returns the claims hash on success, or +nil+ when
    # the token is expired, malformed, denylisted, or does not carry the correct purpose.
    def self.decode_magic_link(token)
      claims = decode(token)
      return nil if claims.nil?
      return nil unless claims[:purpose] == MAGIC_LINK_PURPOSE

      claims
    end
  end
end
