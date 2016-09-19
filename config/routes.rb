require 'sidekiq/web'

Rails.application.routes.draw do
  mount ActionCable.server => '/cable'

  authenticate :user, ->(u) { u.admin? } do
    mount Sidekiq::Web => '/admin/sidekiq'
  end

  devise_for :users, :skip => :registration, :controllers => {
    :omniauth_callbacks => :omniauth_callbacks
  }

  devise_scope :user do
    resource :registration,
      :only => [:new, :create],
      :path => 'users',
      :path_names => { :new => 'sign_up' },
      :controller => :registrations,
      :as => :user_registration do
        get :cancel
      end
  end

  root 'welcome#index'

  resources :users, :only => [:edit, :show, :update] do
    get :settings, :dashboard, :on => :member

    resources :authentications, :only => [:index, :destroy]

    resources :projects, :only => [:new, :index, :create, :destroy, :update, :edit] do
      get :stop_sync_with_github, :stop_sync_with_bitbucket, :stop_sync_with_gitlab,
        :sync_from_github, :sync_from_bitbucket, :sync_from_gitlab, :on => :collection
    end

    resources :boards, :user_requests, :except => [:show]

    resources :issues, :only => [:new, :create, :index, :edit, :update]
  end

  resources :projects, :only => [:show] do
    resources :issues

    resources :users, :only => [:index]

    resources :changelogs, :only => [:index, :show] do
      get :resend, :on => :member

      get :sync, :on => :collection
    end

    post :payload_from_github, :payload_from_bitbucket, :payload_from_gitlab, :on => :member
  end

  resources :boards, :only => [:show] do
    resources :issues

    resources :users, :except => [:edit, :update, :destroy, :show]
  end

  resources :news, :only => [:index, :show]

  resources :pages, :only => [:show]

  resources :user_requests, :only => [:index]

  resources :feedbacks, :only => [:new, :create]

  get '/robots.:format' => 'pages#robots'
end
