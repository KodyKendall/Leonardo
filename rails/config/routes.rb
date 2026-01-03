# LEONARDO WAS HERE
Rails.application.routes.draw do
  resources :section_categories
  resources :preliminaries_general_item_templates, path: 'p_and_g_templates'
  # resources :preliminaries_general_items
  resources :tender_equipment_summaries
  resources :equipment_types
  resources :on_site_mobile_crane_breakdowns do
    member do
      get :builder
      post :populate_crane_selections
    end
  end
  post "tenders/:tender_id/ensure_breakdown", to: "on_site_mobile_crane_breakdowns#ensure_breakdown", as: "ensure_breakdown"
  resources :tender_crane_selections
  resources :crane_complements
  resources :crane_rates
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
      post :create_line_items
      patch :update_attributes
    end
  end
  resources :boq_items
  resources :clients do
    member do
      get :contacts
    end
  end
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
      get :tender_inclusions_exclusions
      patch :update_inclusions_exclusions
      post :mirror_boq_items
      post :attach_boq, to: "boqs#attach_boq"
      get :material_autofill
    end
    collection do
      post :quick_create
    end
    resources :boqs, only: [:create]
    resources :tender_line_items do
      collection do
        patch :reorder
      end
    end
    resources :tender_specific_material_rates do
      collection do
        post :populate_from_month
      end
    end
    resources :project_rate_build_ups, only: [:edit, :update, :show]
    resources :equipment_selections
    resources :preliminaries_general_items, path: 'p_and_g' do
      collection do
        get :totals
      end
    end
  end

  resources :suppliers
  resources :material_supplies
  resources :monthly_material_supply_rates do
    member do
      post :save_rate
      post :set_2nd_cheapest_as_winners
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

  # Requirements browser
  get "requirements" => "requirements#index"
  get "requirements/*path" => "requirements#index", as: :requirements_path, constraints: { path: /.*/ }, defaults: { format: :html }

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