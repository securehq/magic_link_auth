Rails.application.routes.draw do
  mount MagicLinkAuth::Engine, at: "/auth"
  root to: "application#index"
end
