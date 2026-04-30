module MagicLinkAuth
  class ApplicationController < ActionController::Base
    include MagicLinkAuth::Authentication
  end
end
