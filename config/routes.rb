# frozen_string_literal: true

Rails.application.routes.draw do
  root "home#index"
  get  "stats", to: "home#stats"

  resources :dispatches, only: [ :create ]
  resources :storms,     only: [ :create ]

  mount DispatchPolicy::Engine => "/dispatch_policy"
  mount GoodJob::Engine => "/good_job"

  get "up" => "rails/health#show", as: :rails_health_check
end
