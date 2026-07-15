Rails.application.routes.draw do
  get "health", to: "health#show"

  get "clinicians", to: "clinicians#index"
  get "clinicians/:name/slots", to: "clinicians/slots#index", constraints: { name: /[^\/]+/ }
  post "appointments", to: "appointments#create"
  delete "appointments/:id", to: "appointments#destroy"
  get "patients/:patient_id/appointments", to: "patients/appointments#index"

  match "*path", to: "application#route_not_found", via: :all
end
