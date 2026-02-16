Rails.application.routes.draw do
  ##get "my_registrations/", to: "my_registrations#index"
  resources :my_registrations, only: [ :index ]

  namespace :settings do
    resource :email, only: [ :show, :update ]
    resource :password, only: [ :show, :update ]
    resource :profile, only: [ :show, :update ]
    resource :user, only: [ :show, :destroy ]

    root to: redirect("/settings/profile")
  end

  namespace :email do
    resources :confirmations, param: :token, only: [ :show ]
  end

  # Admins Only
  namespace :store do
    resources :users
  end

  resource :session
  resources :passwords, param: :token
  # resource :sign_up
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "sailings#index"

  resources :sailings
  # Add a new, non-REST, route to SailingsController
  get "sailings/:id/registrations", to: "sailings#registration", as: "registrations"

  # Assignment - not sure what routes I need TODO
  resources :assignments
end
