# frozen_string_literal: true

Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  get "login", to: "web/sessions#new"
  post "login", to: "web/sessions#create"

  get "saml/metadata", to: "saml/idp#metadata"
  match "saml/auth", to: "saml/idp#auth", via: %i[get post], as: :saml_auth

  namespace :api do
    namespace :v1 do
      post "login", to: "sessions#create"
      resources :client_applications, only: %i[index create]
    end
  end
end
