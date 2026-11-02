Rails.application.routes.draw do
  root "dashboard#show"

  resources :games, only: %i[index show], param: :slug
  resources :tags, only: :index

  get "up" => "rails/health#show", as: :rails_health_check
end
