Rails.application.routes.draw do
  resources :line_item_material_breakdowns
  resources :line_item_materials
  resources :line_item_rate_build_ups
  resources :boqs do
    collection do
      get :search
    end
    member do
      post :parse
      get :csv_download
      get :csv_as_json
      patch :update_header_row
      get :export_boq_csv
      post :detach
    end
  end
  resources :boq_items
  resources :clients
  resources :fabrication_records
  resources :budget_allowances
  resources :budget_categories
  resources :variation_orders
  resources :claim_line_items
  resources :claims
  resources :projects
  resources :tenders do
    member do
      get :builder
      patch :update_inclusions_exclusions
      post :mirror_boq_items
      post :attach_boq, to: "boqs#attach_boq"
    end
    collection do
      post :quick_create
    end
    resources :boqs, only: [:create]
    resources :tender_line_items
  end

    resources :tender_line_items

  resources :suppliers
  resources :material_supplies
  resources :monthly_material_supply_rates do
    member do
      post :save_rate
    end
  end
  resources :material_supply_rates
  devise_for :users, controllers: { registrations: 'users/registrations' }
  resources :users do
    member do
      get :generate_profile_pic, action: :generate_profile_pic_form
      post :generate_profile_pic
      get :generate_bio_audio, action: :generate_bio_audio_form
      post :generate_bio_audio
    end
  end
  mount LlamaBotRails::Engine => "/llama_bot"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  root "dashboards#index"
  get "dashboard" => "dashboards#index"
  get "old_dashboard" => "dashboards#old_dashboard"
  post "upload_tender_qob" => "dashboards#upload_tender_qob"
  get "api/dashboard_metrics" => "dashboards#metrics"
  # root "prototypes#show", page: "home"
  get "home" => "public#home"
  get "chat" => "public#chat"

  namespace :admin do
    root to: "dashboard#index"
    
    resources :users do
      member do
        post :impersonate
      end
    end
  end
  
  post "/stop_impersonating", to: "application#stop_impersonating"


  get "/prototypes/*page", to: "prototypes#show"
  # Defines the root path route ("/")
  # root "posts#index"
end