class User < ActiveRecord::Base
  include MagicLinkAuth::Authenticatable
end
