Rails.application.routes.draw do
  # OAuth
  get "/auth/:provider/callback", to: "sessions#create"
  get "/auth/failure", to: "sessions#failure"

  # Sessions
  get "/login", to: "sessions#new", as: :login
  delete "/logout", to: "sessions#destroy", as: :logout

  # Dashboard
  root "dashboard#index"

  # Leagues and nested resources
  resources :leagues, only: [:index, :show] do
    resources :seasons, only: [:show] do
      resources :matchups, only: [:index, :show]
      resources :standings, only: [:index]
    end
    member do
      get :lifetime_records
      get :head_to_head
    end
  end

  # Managers
  resources :managers, only: [:index, :show]

  # Sync actions
  namespace :admin do
    post "sync/leagues", to: "sync#leagues"
    post "sync/season/:season_id", to: "sync#season", as: :sync_season
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
