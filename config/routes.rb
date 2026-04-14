Rails.application.routes.draw do
  resource :session
  resource :profile, only: [ :show, :edit, :update ]
  resources :passwords, param: :token
  resources :enrollments, only: [ :index, :show, :new, :create, :update, :destroy ], path: "courses" do
    collection do
      get :dashboard
    end
  end
  resources :deadlines, only: [ :index, :new, :create, :destroy ]

  # Course catalog (browse all courses before adding to plan)
  get "catalog" => "courses#index", as: :catalog
  get "catalog/:key" => "courses#show", as: :catalog_course

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "pages#home"
  get "about" => "pages#about"
  get "documents" => "pages#documents"

  # Document storage API (server mode)
  get "documents/check/:key" => "documents#check", as: :check_document
  get "documents/file/:key" => "documents#show", as: :document_file
  post "documents/file/:key" => "documents#create"
  delete "documents/file/:key" => "documents#destroy"
end
