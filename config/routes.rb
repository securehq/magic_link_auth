MagicLinkAuth::Engine.routes.draw do
  # Web (cookie-session) routes
  resource :session, only: %i[new create destroy] do
    get :verify,          on: :collection
    get :magic_link_sent, on: :collection
  end

  # API (JWT) routes
  namespace :api do
    resource :session, only: %i[create destroy], controller: "sessions" do
      post :verify, on: :collection
    end
  end

  # Mobile deep-link verification files (only drawn when deep_link_scheme is configured)
  if MagicLinkAuth.configuration.deep_link_enabled?
    get "/.well-known/apple-app-site-association" => "well_known#apple_app_site_association",
        as: :apple_app_site_association
    get "/.well-known/assetlinks.json" => "well_known#assetlinks",
        as: :assetlinks
  end
end
