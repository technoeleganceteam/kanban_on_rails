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
    post 'omniauth_finish' => 'omniauth_callbacks#omniauth_finish'

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

    resources :projects, :only => [:index, :create, :destroy, :update, :edit] do
      get :stop_sync_with_github, :stop_sync_with_bitbucket,
        :sync_with_github, :sync_with_bitbucket, :on => :collection
    end
  end

  resources :projects, :only => [:show]  do
    resources :issues

    resources :users, :except => [:edit, :update, :destroy, :show]

    post :payload_from_github, :payload_from_bitbucket, :on => :member
  end

  resources :news, :only => [:index, :show]

  resources :pages, :only => [:show]

  get '/robots.:format' => 'pages#robots'
end
