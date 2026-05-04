class ApplicationController < ActionController::Base
  include MagicLinkAuth::Authentication

  allow_unauthenticated_access only: :index

  def index
    render plain: "home"
  end
end
