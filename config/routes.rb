MediaCrawler::Application.routes.draw do
  
  resources :resources
  resources :servers, :only => [:index] do
    member do
      get 'filelist'
    end
    resources :files, only: :index
  end

  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'
  
  get 'usage'     => 'static#usage'
  get 'resources' => 'resources#index'
  
  root :to => "paths#index"

  # See how all your routes lay out with "rake routes"

end
