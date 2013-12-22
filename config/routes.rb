MediaCrawler::Application.routes.draw do
  
  resources :resources
  resources :servers, :only => [:index]
  
  get 'usage' => 'static#usage'
  
  root :to => "resources#index"

  # See how all your routes lay out with "rake routes"

end
