MediaCrawler::Application.routes.draw do

  get 'servers'     => 'servers#index'
  get 'servers/:id' => 'files#index', id: /[^\/]+/, as: :server_files

  get 'usage'     => 'static#usage'
  get 'resources' => 'resources#index'

  root :to => "paths#index"

  # See how all your routes lay out with "rake routes"

end
