Rails.application.routes.draw do
  root "health#show"
  get "health", to: "health#show"
  get "json/version", to: "health#version"

  post "auth/login", to: "auth#create"
  get "auth/me", to: "auth#me"

  get "clinicians", to: "clinicians#index"
  post "clinicians", to: "clinicians#create"
  get "clinicians/:name/slots", to: "clinicians/slots#index", constraints: { name: /[^\/]+/ }
  get "appointments", to: "appointments#index"
  post "appointments", to: "appointments#create"
  delete "appointments/:id", to: "appointments#destroy"
  get "patients", to: "patients#index"
  post "patients", to: "patients#create"
  get "patients/:patient_id/appointments", to: "patients/appointments#index"

  match "*path", to: "application#route_not_found", via: :all
end
